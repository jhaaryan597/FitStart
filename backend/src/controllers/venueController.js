const Venue = require('../models/Venue');
const User = require('../models/User');
const MLInteraction = require('../models/MLInteraction');

// @desc    Get all venues
// @route   GET /api/v1/venues
// @access  Public
exports.getVenues = async (req, res, next) => {
  try {
    const {
      category,
      search,
      minPrice,
      maxPrice,
      minRating,
      latitude,
      longitude,
      maxDistance, // in kilometers
      sortBy = 'createdAt',
      order = 'desc',
      page = 1,
      limit = 20,
    } = req.query;

    // Build query
    let query = { isActive: true };

    // Category filter
    if (category && category !== 'all') {
      query.category = category;
    }

    // Price filter
    if (minPrice || maxPrice) {
      query['pricing.hourlyRate'] = {};
      if (minPrice) query['pricing.hourlyRate'].$gte = Number(minPrice);
      if (maxPrice) query['pricing.hourlyRate'].$lte = Number(maxPrice);
    }

    // Rating filter
    if (minRating) {
      query['rating.average'] = { $gte: Number(minRating) };
    }

    // Text search
    if (search) {
      query.$text = { $search: search };
    }

    // Location-based query
    if (latitude && longitude) {
      const maxDist = maxDistance ? Number(maxDistance) * 1000 : 50000; // Default 50km
      
      query.location = {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [Number(longitude), Number(latitude)],
          },
          $maxDistance: maxDist,
        },
      };
    }

    // Sorting
    let sortOptions = {};
    if (sortBy === 'price') {
      sortOptions['pricing.hourlyRate'] = order === 'asc' ? 1 : -1;
    } else if (sortBy === 'rating') {
      sortOptions['rating.average'] = order === 'asc' ? 1 : -1;
    } else if (sortBy === 'popular') {
      sortOptions.bookingCount = -1;
    } else {
      sortOptions[sortBy] = order === 'asc' ? 1 : -1;
    }

    // Pagination
    const skip = (Number(page) - 1) * Number(limit);

    // Execute query
    const venues = await Venue.find(query)
      .sort(sortOptions)
      .limit(Number(limit))
      .skip(skip)
      .populate('owner', 'username email');

    // Get total count
    const total = await Venue.countDocuments(query);

    res.status(200).json({
      success: true,
      count: venues.length,
      total,
      page: Number(page),
      pages: Math.ceil(total / Number(limit)),
      data: venues,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get single venue
// @route   GET /api/v1/venues/:id
// @access  Public
exports.getVenue = async (req, res, next) => {
  try {
    const venue = await Venue.findById(req.params.id).populate('owner', 'username email');

    if (!venue) {
      return res.status(404).json({
        success: false,
        message: 'Venue not found',
      });
    }

    // Track view interaction if user is logged in
    if (req.user) {
      await MLInteraction.create({
        user: req.user.id,
        venue: venue._id,
        interactionType: 'view',
      });
    }

    res.status(200).json({
      success: true,
      data: venue,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create new venue
// @route   POST /api/v1/venues
// @access  Private (Admin/Venue Owner)
exports.createVenue = async (req, res, next) => {
  try {
    req.body.owner = req.user.id;
    
    // Set location coordinates
    if (req.body.latitude && req.body.longitude) {
      req.body.location = {
        type: 'Point',
        coordinates: [Number(req.body.longitude), Number(req.body.latitude)],
      };
    }

    const venue = await Venue.create(req.body);

    res.status(201).json({
      success: true,
      data: venue,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update venue
// @route   PUT /api/v1/venues/:id
// @access  Private (Owner/Admin)
exports.updateVenue = async (req, res, next) => {
  try {
    let venue = await Venue.findById(req.params.id);

    if (!venue) {
      return res.status(404).json({
        success: false,
        message: 'Venue not found',
      });
    }

    // Check ownership
    if (venue.owner.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to update this venue',
      });
    }

    // Update location if coordinates provided
    if (req.body.latitude && req.body.longitude) {
      req.body.location = {
        type: 'Point',
        coordinates: [Number(req.body.longitude), Number(req.body.latitude)],
      };
    }

    venue = await Venue.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });

    res.status(200).json({
      success: true,
      data: venue,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete venue
// @route   DELETE /api/v1/venues/:id
// @access  Private (Owner/Admin)
exports.deleteVenue = async (req, res, next) => {
  try {
    const venue = await Venue.findById(req.params.id);

    if (!venue) {
      return res.status(404).json({
        success: false,
        message: 'Venue not found',
      });
    }

    // Check ownership
    if (venue.owner.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this venue',
      });
    }

    await venue.deleteOne();

    res.status(200).json({
      success: true,
      message: 'Venue deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Add/Remove venue from favorites
// @route   POST /api/v1/venues/:id/favorite
// @access  Private
exports.toggleFavorite = async (req, res, next) => {
  try {
    const venue = await Venue.findById(req.params.id);

    if (!venue) {
      return res.status(404).json({
        success: false,
        message: 'Venue not found',
      });
    }

    const user = await User.findById(req.user.id);
    const favoriteIndex = user.favorites.indexOf(venue._id);

    if (favoriteIndex > -1) {
      // Remove from favorites
      user.favorites.splice(favoriteIndex, 1);
      await user.save();

      // Track unfavorite interaction
      await MLInteraction.create({
        user: user._id,
        venue: venue._id,
        interactionType: 'unfavorite',
      });

      res.status(200).json({
        success: true,
        message: 'Removed from favorites',
        isFavorite: false,
      });
    } else {
      // Add to favorites
      user.favorites.push(venue._id);
      await user.save();

      // Track favorite interaction
      await MLInteraction.create({
        user: user._id,
        venue: venue._id,
        interactionType: 'favorite',
      });

      res.status(200).json({
        success: true,
        message: 'Added to favorites',
        isFavorite: true,
      });
    }
  } catch (error) {
    next(error);
  }
};

// @desc    Get user's favorite venues
// @route   GET /api/v1/venues/favorites
// @access  Private
exports.getFavorites = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id).populate('favorites');

    res.status(200).json({
      success: true,
      count: user.favorites.length,
      data: user.favorites,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get nearby venues
// @route   GET /api/v1/venues/nearby
// @access  Public
exports.getNearbyVenues = async (req, res, next) => {
  try {
    const { latitude, longitude, maxDistance = 10 } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Please provide latitude and longitude',
      });
    }

    const venues = await Venue.find({
      isActive: true,
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [Number(longitude), Number(latitude)],
          },
          $maxDistance: Number(maxDistance) * 1000, // Convert km to meters
        },
      },
    }).limit(20);

    res.status(200).json({
      success: true,
      count: venues.length,
      data: venues,
    });
  } catch (error) {
    next(error);
  }
};
