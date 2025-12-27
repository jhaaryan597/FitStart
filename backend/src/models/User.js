const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    username: {
      type: String,
      required: [true, 'Username is required'],
      unique: true,
      trim: true,
      minlength: [3, 'Username must be at least 3 characters long'],
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, 'Please provide a valid email'],
    },
    password: {
      type: String,
      required: function() {
        // Password only required if not using Google/social auth
        return this.authProvider === 'email';
      },
      minlength: [6, 'Password must be at least 6 characters long'],
      select: false, // Don't return password by default
    },
    googleId: {
      type: String,
      sparse: true,
      unique: true,
    },
    authProvider: {
      type: String,
      enum: ['email', 'google'],
      default: 'email',
    },
    profileImage: {
      type: String,
      default: null,
    },
    phoneNumber: {
      type: String,
      default: null,
    },
    fcmTokens: [{
      token: String,
      platform: {
        type: String,
        enum: ['android', 'ios', 'web'],
        default: 'android',
      },
      createdAt: {
        type: Date,
        default: Date.now,
      },
    }],
    preferences: {
      notificationsEnabled: {
        type: Boolean,
        default: true,
      },
      emailNotifications: {
        type: Boolean,
        default: true,
      },
      sportsInterests: [{
        type: String,
      }],
      preferredLocation: {
        latitude: Number,
        longitude: Number,
        address: String,
      },
    },
    favorites: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Venue',
    }],
    role: {
      type: String,
      enum: ['user', 'admin', 'venue_owner'],
      default: 'user',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    lastLogin: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Compare password method
userSchema.methods.comparePassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Remove sensitive data when converting to JSON
userSchema.methods.toJSON = function () {
  const user = this.toObject();
  delete user.password;
  delete user.__v;
  return user;
};

module.exports = mongoose.model('User', userSchema);
