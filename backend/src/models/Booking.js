const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    venue: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Venue',
      required: true,
    },
    bookingDate: {
      type: Date,
      required: [true, 'Booking date is required'],
    },
    timeSlots: [{
      startTime: {
        type: String,
        required: true,
      },
      endTime: {
        type: String,
        required: true,
      },
    }],
    totalHours: {
      type: Number,
      required: true,
    },
    pricing: {
      hourlyRate: Number,
      totalAmount: {
        type: Number,
        required: true,
      },
      currency: {
        type: String,
        default: 'INR',
      },
    },
    payment: {
      status: {
        type: String,
        enum: ['pending', 'completed', 'failed', 'refunded'],
        default: 'pending',
      },
      method: {
        type: String,
        enum: ['razorpay', 'cash', 'card', 'wallet'],
        default: 'razorpay',
      },
      transactionId: String,
      razorpayOrderId: String,
      razorpayPaymentId: String,
      razorpaySignature: String,
      paidAt: Date,
    },
    bookingStatus: {
      type: String,
      enum: ['pending', 'confirmed', 'cancelled', 'completed', 'no_show'],
      default: 'pending',
    },
    cancellationReason: {
      type: String,
    },
    cancelledAt: {
      type: Date,
    },
    notes: {
      type: String,
    },
  },
  {
    timestamps: true,
  }
);

// Index for efficient queries
bookingSchema.index({ user: 1, createdAt: -1 });
bookingSchema.index({ venue: 1, bookingDate: 1 });
bookingSchema.index({ bookingStatus: 1 });

// Check for booking conflicts
bookingSchema.statics.checkConflict = async function (venueId, bookingDate, timeSlots) {
  const conflicts = await this.find({
    venue: venueId,
    bookingDate: bookingDate,
    bookingStatus: { $in: ['pending', 'confirmed'] },
    timeSlots: {
      $elemMatch: {
        $or: timeSlots.map(slot => ({
          startTime: { $lt: slot.endTime },
          endTime: { $gt: slot.startTime },
        })),
      },
    },
  });
  
  return conflicts.length > 0;
};

module.exports = mongoose.model('Booking', bookingSchema);
