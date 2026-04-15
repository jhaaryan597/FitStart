const mongoose = require('mongoose');

const gymMembershipSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    gym: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Gym',
      required: true,
    },
    planType: {
      type: String,
      enum: ['daily', 'weekly', 'monthly', 'quarterly', 'yearly'],
      required: true,
    },
    startDate: {
      type: Date,
      required: true,
    },
    endDate: {
      type: Date,
      required: true,
    },
    withTrainer: {
      type: Boolean,
      default: false,
    },
    pricing: {
      basePrice: Number,
      trainerPrice: Number,
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
    membershipStatus: {
      type: String,
      enum: ['active', 'expired', 'cancelled', 'frozen'],
      default: 'active',
    },
    autoRenew: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// Index for efficient queries
gymMembershipSchema.index({ user: 1, membershipStatus: 1 });
gymMembershipSchema.index({ gym: 1, membershipStatus: 1 });
gymMembershipSchema.index({ endDate: 1 });

module.exports = mongoose.model('GymMembership', gymMembershipSchema);
