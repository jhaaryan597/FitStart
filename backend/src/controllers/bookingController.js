const Booking = require('../models/Booking');
const Venue = require('../models/Venue');
const Notification = require('../models/Notification');
const User = require('../models/User');
const { sendNotification } = require('../config/firebase');
const Razorpay = require('razorpay');
const crypto = require('crypto');

// Initialize Razorpay (optional - only if credentials are configured)
let razorpay = null;
if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
  razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET,
  });
  console.log('✅ Razorpay payment gateway initialized');
} else {
  console.log('⚠️  Razorpay credentials not configured - payments disabled');
}

// @desc    Get all bookings for a user
// @route   GET /api/v1/bookings
// @access  Private
exports.getBookings = async (req, res, next) => {
  try {
    const { status, startDate, endDate, page = 1, limit = 20 } = req.query;

    let query = { user: req.user.id };

    if (status) {
      const normalizedStatus = String(status).toLowerCase() === 'cancelled'
        ? 'cancelled'
        : status;
      query.bookingStatus = normalizedStatus;
    }

    if (startDate || endDate) {
      query.bookingDate = {};
      if (startDate) query.bookingDate.$gte = new Date(startDate);
      if (endDate) query.bookingDate.$lte = new Date(endDate);
    }

    const skip = (Number(page) - 1) * Number(limit);

    const bookings = await Booking.find(query)
      .populate('venue', 'name address phoneNumber images')
      .sort({ createdAt: -1 })
      .limit(Number(limit))
      .skip(skip);

    const total = await Booking.countDocuments(query);

    res.status(200).json({
      success: true,
      count: bookings.length,
      total,
      page: Number(page),
      pages: Math.ceil(total / Number(limit)),
      data: bookings,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get single booking
// @route   GET /api/v1/bookings/:id
// @access  Private
exports.getBooking = async (req, res, next) => {
  try {
    const booking = await Booking.findById(req.params.id)
      .populate('venue', 'name address phoneNumber images openTime closeTime')
      .populate('user', 'username email phoneNumber');

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found',
      });
    }

    // Check ownership
    if (booking.user._id.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to access this booking',
      });
    }

    res.status(200).json({
      success: true,
      data: booking,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create new booking
// @route   POST /api/v1/bookings
// @access  Private
exports.createBooking = async (req, res, next) => {
  try {
    const { venueId, bookingDate, timeSlots, notes } = req.body;

    if (!razorpay) {
      return res.status(503).json({
        success: false,
        message: 'Payments are temporarily unavailable',
      });
    }

    if (!Array.isArray(timeSlots) || timeSlots.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'At least one time slot is required',
      });
    }

    // Validate booking date — must not be in the past or more than 90 days ahead
    const bookingDateObj = new Date(bookingDate);
    const now = new Date();
    now.setHours(0, 0, 0, 0);
    const maxDate = new Date();
    maxDate.setDate(maxDate.getDate() + 90);

    if (isNaN(bookingDateObj.getTime())) {
      return res.status(400).json({ success: false, message: 'Invalid booking date' });
    }
    if (bookingDateObj < now) {
      return res.status(400).json({ success: false, message: 'Booking date cannot be in the past' });
    }
    if (bookingDateObj > maxDate) {
      return res.status(400).json({ success: false, message: 'Cannot book more than 90 days in advance' });
    }

    const timeToMinutes = (t) => {
      const [h, m] = String(t).split(':').map(Number);
      return h * 60 + (m || 0);
    };

    const hasInvalidSlot = timeSlots.some(
      (slot) =>
        !slot?.startTime ||
        !slot?.endTime ||
        timeToMinutes(slot.startTime) >= timeToMinutes(slot.endTime)
    );

    if (hasInvalidSlot) {
      return res.status(400).json({
        success: false,
        message: 'Invalid time slot(s) provided',
      });
    }

    // Check if venue exists
    const venue = await Venue.findById(venueId);
    if (!venue) {
      return res.status(404).json({
        success: false,
        message: 'Venue not found',
      });
    }

    // Check for booking conflicts
    const hasConflict = await Booking.checkConflict(venueId, new Date(bookingDate), timeSlots);
    if (hasConflict) {
      return res.status(400).json({
        success: false,
        message: 'Selected time slots are not available',
      });
    }

    // Calculate total hours and amount (supports half-hour slots)
    const totalHours = timeSlots.reduce((sum, slot) => {
      const startMins = timeToMinutes(slot.startTime);
      const endMins = timeToMinutes(slot.endTime);
      return sum + (endMins - startMins) / 60;
    }, 0);

    const totalAmount = totalHours * venue.pricing.hourlyRate;

    // Create Razorpay order
    const razorpayOrder = await razorpay.orders.create({
      amount: totalAmount * 100, // Amount in paise
      currency: 'INR',
      receipt: `booking_${Date.now()}`,
    });

    // Create booking
    const booking = await Booking.create({
      user: req.user.id,
      venue: venueId,
      bookingDate: new Date(bookingDate),
      timeSlots,
      totalHours,
      pricing: {
        hourlyRate: venue.pricing.hourlyRate,
        totalAmount,
        currency: venue.pricing.currency,
      },
      payment: {
        razorpayOrderId: razorpayOrder.id,
      },
      notes,
    });

    res.status(201).json({
      success: true,
      data: booking,
      razorpayOrderId: razorpayOrder.id,
      razorpayKeyId: process.env.RAZORPAY_KEY_ID,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Verify payment and confirm booking
// @route   POST /api/v1/bookings/:id/verify-payment
// @access  Private
exports.verifyPayment = async (req, res, next) => {
  try {
    const { razorpayPaymentId, razorpaySignature } = req.body;

    // Fetch the booking and check ownership before doing any crypto work
    const rawBooking = await Booking.findById(req.params.id);

    if (!rawBooking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    if (rawBooking.user.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized to verify payment for this booking' });
    }

    if (rawBooking.payment?.status === 'completed') {
      return res.status(400).json({ success: false, message: 'Payment already verified for this booking' });
    }

    // Verify Razorpay signature before touching the DB
    const text = rawBooking.payment.razorpayOrderId + '|' + razorpayPaymentId;
    const expectedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(text)
      .digest('hex');

    if (expectedSignature !== razorpaySignature) {
      return res.status(400).json({ success: false, message: 'Invalid payment signature' });
    }

    // Atomic update — only succeeds if payment is still pending,
    // preventing a double-verification race condition
    const booking = await Booking.findOneAndUpdate(
      { _id: req.params.id, 'payment.status': { $ne: 'completed' } },
      {
        $set: {
          'payment.status': 'completed',
          'payment.razorpayPaymentId': razorpayPaymentId,
          'payment.razorpaySignature': razorpaySignature,
          'payment.paidAt': new Date(),
          bookingStatus: 'confirmed',
        },
      },
      { new: true }
    ).populate('venue');

    if (!booking) {
      return res.status(400).json({ success: false, message: 'Payment already verified for this booking' });
    }

    // Update venue booking count
    booking.venue.bookingCount += 1;
    await booking.venue.save();

    // Send confirmation notification
    const user = await User.findById(booking.user);
    if (user?.fcmTokens?.length > 0) {
      const fcmToken = user.fcmTokens[0].token;

      try {
        await sendNotification(fcmToken, {
          title: 'Booking Confirmed!',
          body: `Your booking at ${booking.venue.name} has been confirmed.`,
          data: {
            type: 'booking',
            bookingId: booking._id.toString(),
          },
        });
      } catch (notificationError) {
        console.warn('Failed to send booking confirmation push:', notificationError.message);
      }

      // Save notification to database
      await Notification.create({
        user: booking.user,
        title: 'Booking Confirmed!',
        body: `Your booking at ${booking.venue.name} has been confirmed.`,
        type: 'booking',
        data: {
          bookingId: booking._id.toString(),
        },
        sentViaFCM: true,
      });
    }

    res.status(200).json({
      success: true,
      message: 'Payment verified and booking confirmed',
      data: booking,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Cancel booking
// @route   PUT /api/v1/bookings/:id/cancel
// @access  Private
exports.cancelBooking = async (req, res, next) => {
  try {
    const { reason } = req.body;

    const booking = await Booking.findById(req.params.id).populate('venue');

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found',
      });
    }

    // Check ownership
    if (booking.user.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to cancel this booking',
      });
    }

    if (booking.bookingStatus === 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'Booking is already cancelled',
      });
    }

    // Check cancellation policy (e.g., cannot cancel within 24 hours)
    const hoursUntilBooking = (new Date(booking.bookingDate) - new Date()) / (1000 * 60 * 60);
    if (hoursUntilBooking < 24) {
      return res.status(400).json({
        success: false,
        message: 'Cannot cancel booking within 24 hours of scheduled time',
      });
    }

    booking.bookingStatus = 'cancelled';
    booking.cancellationReason = reason ? String(reason).slice(0, 500) : undefined;
    booking.cancelledAt = Date.now();
    await booking.save();

    // Send cancellation notification
    const user = await User.findById(booking.user);
    if (user?.fcmTokens?.length > 0) {
      const fcmToken = user.fcmTokens[0].token;

      try {
        await sendNotification(fcmToken, {
          title: 'Booking Cancelled',
          body: `Your booking at ${booking.venue.name} has been cancelled.`,
          data: {
            type: 'booking',
            bookingId: booking._id.toString(),
          },
        });
      } catch (notificationError) {
        console.warn('Failed to send booking cancellation push:', notificationError.message);
      }

      await Notification.create({
        user: booking.user,
        title: 'Booking Cancelled',
        body: `Your booking at ${booking.venue.name} has been cancelled.`,
        type: 'booking',
        data: {
          bookingId: booking._id.toString(),
        },
        sentViaFCM: true,
      });
    }

    res.status(200).json({
      success: true,
      message: 'Booking cancelled successfully',
      data: booking,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get available time slots for a venue on a date
// @route   GET /api/v1/bookings/available-slots/:venueId
// @access  Public
exports.getAvailableSlots = async (req, res, next) => {
  try {
    const { date } = req.query;
    const venueId = req.params.venueId;

    if (!date) {
      return res.status(400).json({
        success: false,
        message: 'Date is required',
      });
    }

    const venue = await Venue.findById(venueId);
    if (!venue) {
      return res.status(404).json({
        success: false,
        message: 'Venue not found',
      });
    }

    // Get all bookings for this venue on this date
    const bookings = await Booking.find({
      venue: venueId,
      bookingDate: new Date(date),
      bookingStatus: { $in: ['pending', 'confirmed'] },
    });

    // Extract booked time slots
    const bookedSlots = [];
    bookings.forEach(booking => {
      booking.timeSlots.forEach(slot => {
        bookedSlots.push({
          startTime: slot.startTime,
          endTime: slot.endTime,
        });
      });
    });

    res.status(200).json({
      success: true,
      data: {
        venueOpenTime: venue.openTime,
        venueCloseTime: venue.closeTime,
        bookedSlots,
      },
    });
  } catch (error) {
    next(error);
  }
};
