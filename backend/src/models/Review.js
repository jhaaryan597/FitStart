const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    venue: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Venue',
    },
    gym: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Gym',
    },
    booking: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Booking',
    },
    rating: {
      type: Number,
      required: [true, 'Rating is required'],
      min: 1,
      max: 5,
    },
    comment: {
      type: String,
      maxlength: [500, 'Comment cannot exceed 500 characters'],
    },
    images: [{
      url: String,
      publicId: String,
    }],
    isVerifiedBooking: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// Index for efficient queries
reviewSchema.index({ venue: 1, createdAt: -1 });
reviewSchema.index({ gym: 1, createdAt: -1 });
reviewSchema.index({ user: 1 });

// Prevent duplicate reviews from same user for same venue/gym
reviewSchema.index({ user: 1, venue: 1 }, { unique: true, sparse: true });
reviewSchema.index({ user: 1, gym: 1 }, { unique: true, sparse: true });

module.exports = mongoose.model('Review', reviewSchema);
