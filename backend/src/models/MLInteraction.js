const mongoose = require('mongoose');

const mlInteractionSchema = new mongoose.Schema(
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
    interactionType: {
      type: String,
      enum: ['view', 'favorite', 'booking', 'unfavorite', 'search', 'share'],
      required: true,
    },
    duration: {
      type: Number, // seconds spent viewing
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for ML queries
mlInteractionSchema.index({ user: 1, interactionType: 1, createdAt: -1 });
mlInteractionSchema.index({ venue: 1, interactionType: 1 });
mlInteractionSchema.index({ gym: 1, interactionType: 1 });

module.exports = mongoose.model('MLInteraction', mlInteractionSchema);
