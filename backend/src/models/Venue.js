const mongoose = require('mongoose');

const venueSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Venue name is required'],
      trim: true,
    },
    category: {
      type: String,
      required: [true, 'Category is required'],
      enum: ['football', 'basketball', 'badminton', 'tennis', 'volleyball', 'cricket', 'swimming', 'gym', 'other'],
    },
    description: {
      type: String,
      default: '',
    },
    facilities: [{
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
    pricing: {
      hourlyRate: {
        type: Number,
        required: [true, 'Hourly rate is required'],
      },
      currency: {
        type: String,
        default: 'INR',
      },
    },
    images: [{
      url: String,
      publicId: String, // Cloudinary public ID
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
    isVerified: {
      type: Boolean,
      default: false,
    },
    bookingCount: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

// Create geospatial index for location-based queries
venueSchema.index({ location: '2dsphere' });

// Index for text search
venueSchema.index({ name: 'text', description: 'text', address: 'text' });

// Virtual for favorited count
venueSchema.virtual('favoritedCount', {
  ref: 'User',
  localField: '_id',
  foreignField: 'favorites',
  count: true,
});

module.exports = mongoose.model('Venue', venueSchema);
