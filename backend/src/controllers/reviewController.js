const Review = require('../models/Review');
const Venue = require('../models/Venue');
const Gym = require('../models/Gym');
const Booking = require('../models/Booking');

// @desc    Get reviews for a venue or gym
// @route   GET /api/v1/reviews?venueId=x  OR  ?gymId=x
// @access  Public
exports.getReviews = async (req, res, next) => {
  try {
    const { venueId, gymId, page = 1, limit = 20 } = req.query;

    if (!venueId && !gymId) {
      return res.status(400).json({
        success: false,
        message: 'Provide venueId or gymId as a query parameter',
      });
    }

    const query = venueId ? { venue: venueId } : { gym: gymId };
    const skip = (Number(page) - 1) * Number(limit);

    const reviews = await Review.find(query)
      .populate('user', 'username profileImage')
      .sort({ createdAt: -1 })
      .limit(Number(limit))
      .skip(skip);

    const total = await Review.countDocuments(query);

    res.status(200).json({
      success: true,
      count: reviews.length,
      total,
      page: Number(page),
      pages: Math.ceil(total / Number(limit)),
      data: reviews,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create a review
// @route   POST /api/v1/reviews
// @access  Private
exports.createReview = async (req, res, next) => {
  try {
    const { venueId, gymId, bookingId, rating, comment } = req.body;

    if (!venueId && !gymId) {
      return res.status(400).json({
        success: false,
        message: 'Provide venueId or gymId',
      });
    }

    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be between 1 and 5',
      });
    }

    // Verify the target exists
    if (venueId) {
      const venue = await Venue.findById(venueId);
      if (!venue) {
        return res.status(404).json({ success: false, message: 'Venue not found' });
      }
    } else {
      const gym = await Gym.findById(gymId);
      if (!gym) {
        return res.status(404).json({ success: false, message: 'Gym not found' });
      }
    }

    // Check if booking belongs to user (marks review as verified)
    let isVerifiedBooking = false;
    if (bookingId) {
      const booking = await Booking.findOne({ _id: bookingId, user: req.user.id });
      isVerifiedBooking = !!booking;
    }

    const review = await Review.create({
      user: req.user.id,
      venue: venueId || undefined,
      gym: gymId || undefined,
      booking: bookingId || undefined,
      rating,
      comment,
      isVerifiedBooking,
    });

    // Update the target's average rating
    const targetQuery = venueId ? { venue: venueId } : { gym: gymId };
    const allReviews = await Review.find(targetQuery);
    const avgRating = allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length;

    if (venueId) {
      await Venue.findByIdAndUpdate(venueId, {
        'rating.average': Math.round(avgRating * 10) / 10,
        'rating.count': allReviews.length,
      });
    } else {
      await Gym.findByIdAndUpdate(gymId, {
        'rating.average': Math.round(avgRating * 10) / 10,
        'rating.count': allReviews.length,
      });
    }

    await review.populate('user', 'username profileImage');

    res.status(201).json({
      success: true,
      data: review,
    });
  } catch (error) {
    // Duplicate review — unique index violation
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'You have already reviewed this venue or gym',
      });
    }
    next(error);
  }
};

// @desc    Update a review
// @route   PUT /api/v1/reviews/:id
// @access  Private
exports.updateReview = async (req, res, next) => {
  try {
    const { rating, comment } = req.body;

    const review = await Review.findById(req.params.id);

    if (!review) {
      return res.status(404).json({ success: false, message: 'Review not found' });
    }

    if (review.user.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Not authorized to edit this review' });
    }

    if (rating) {
      if (rating < 1 || rating > 5) {
        return res.status(400).json({ success: false, message: 'Rating must be between 1 and 5' });
      }
      review.rating = rating;
    }
    if (comment !== undefined) review.comment = comment;

    await review.save();

    // Recalculate average rating
    const targetQuery = review.venue ? { venue: review.venue } : { gym: review.gym };
    const allReviews = await Review.find(targetQuery);
    const avgRating = allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length;

    if (review.venue) {
      await Venue.findByIdAndUpdate(review.venue, {
        'rating.average': Math.round(avgRating * 10) / 10,
        'rating.count': allReviews.length,
      });
    } else if (review.gym) {
      await Gym.findByIdAndUpdate(review.gym, {
        'rating.average': Math.round(avgRating * 10) / 10,
        'rating.count': allReviews.length,
      });
    }

    res.status(200).json({ success: true, data: review });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete a review
// @route   DELETE /api/v1/reviews/:id
// @access  Private
exports.deleteReview = async (req, res, next) => {
  try {
    const review = await Review.findById(req.params.id);

    if (!review) {
      return res.status(404).json({ success: false, message: 'Review not found' });
    }

    if (review.user.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized to delete this review' });
    }

    const venueId = review.venue;
    const gymId = review.gym;

    await review.deleteOne();

    // Recalculate average rating after deletion
    const targetQuery = venueId ? { venue: venueId } : { gym: gymId };
    const allReviews = await Review.find(targetQuery);

    if (venueId) {
      await Venue.findByIdAndUpdate(venueId, {
        'rating.average': allReviews.length
          ? Math.round((allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length) * 10) / 10
          : 0,
        'rating.count': allReviews.length,
      });
    } else if (gymId) {
      await Gym.findByIdAndUpdate(gymId, {
        'rating.average': allReviews.length
          ? Math.round((allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length) * 10) / 10
          : 0,
        'rating.count': allReviews.length,
      });
    }

    res.status(200).json({ success: true, message: 'Review deleted' });
  } catch (error) {
    next(error);
  }
};
