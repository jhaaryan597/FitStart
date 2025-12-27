const mongoose = require('mongoose');

const gymSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Gym name is required'],
      trim: true,
    },
    description: {
      type: String,
      default: '',
    },
    amenities: [{
      type: String,
    }],
    address: {
      type: String,
      required: [true, 'Address is required'],
    },
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: true,
      },
    },
    phoneNumber: {
      type: String,
      required: [true, 'Phone number is required'],
    },
    openTime: {
      type: String,
      required: [true, 'Opening time is required'],
    },
    closeTime: {
      type: String,
      required: [true, 'Closing time is required'],
    },
    openDays: {
      type: String,
      default: 'Monday - Sunday',
    },
    membershipPlans: [{
      planType: {
        type: String,
        enum: ['daily', 'weekly', 'monthly', 'quarterly', 'yearly'],
        required: true,
      },
      price: {
        type: Number,
        required: true,
      },
      duration: Number, // in days
      withTrainer: {
        type: Boolean,
        default: false,
      },
      trainerPrice: Number,
    }],
    images: [{
      url: String,
      publicId: String,
      isMain: {
        type: Boolean,
        default: false,
      },
    }],
    rating: {
      average: {
        type: Number,
        default: 0,
        min: 0,
        max: 5,
      },
      count: {
        type: Number,
        default: 0,
      },
    },
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    memberCount: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

// Geospatial index
gymSchema.index({ location: '2dsphere' });

// Text search index
gymSchema.index({ name: 'text', description: 'text', address: 'text' });

module.exports = mongoose.model('Gym', gymSchema);
