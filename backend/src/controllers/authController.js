const User = require('../models/User');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// Generate JWT Token
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE,
  });
};

// @desc    Google Sign In
// @route   POST /api/v1/auth/google
// @access  Public
exports.googleSignIn = async (req, res, next) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({
        success: false,
        message: 'Google ID token is required',
      });
    }

    // Verify Google ID token
    let payload;
    try {
      const ticket = await googleClient.verifyIdToken({
        idToken: idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });
      payload = ticket.getPayload();
    } catch (error) {
      console.error('Google token verification failed:', error);
      return res.status(401).json({
        success: false,
        message: 'Invalid Google ID token',
      });
    }

    const { email, name, picture, sub: googleId } = payload;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email not provided by Google',
      });
    }

    // Check if user exists
    let user = await User.findOne({ email });

    if (!user) {
      // Create new user with Google info
      user = await User.create({
        username: name || email.split('@')[0],
        email,
        profileImage: picture || null,
        googleId,
        authProvider: 'google',
      });
    } else {
      // Update existing user's last login and Google ID if not set
      if (!user.googleId) {
        user.googleId = googleId;
        user.authProvider = 'google';
      }
      user.lastLogin = Date.now();
      await user.save({ validateBeforeSave: false });
    }

    // Create JWT token
    const token = generateToken(user._id);

    res.status(200).json({
      success: true,
      data: {
        user,
        token,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Register user (Legacy - kept for backward compatibility)
// @route   POST /api/v1/auth/register
// @access  Public
exports.register = async (req, res, next) => {
  try {
    const { username, email, password } = req.body;

    // Check if user exists
    const userExists = await User.findOne({ $or: [{ email }, { username }] });
    
    if (userExists) {
      return res.status(400).json({
        success: false,
        message: 'User already exists with this email or username',
      });
    }

    // Create user
    const user = await User.create({
      username,
      email,
      password,
      authProvider: 'email',
    });

    // Create token
    const token = generateToken(user._id);

    res.status(201).json({
      success: true,
      data: {
        user,
        token,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Login user (Legacy - kept for backward compatibility)
// @route   POST /api/v1/auth/login
// @access  Public
exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Validate email & password
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password',
      });
    }

    // Check for user
    const user = await User.findOne({ email }).select('+password');

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Check if password matches
    const isMatch = await user.comparePassword(password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Update last login
    user.lastLogin = Date.now();
    await user.save({ validateBeforeSave: false });

    // Create token
    const token = generateToken(user._id);

    res.status(200).json({
      success: true,
      data: {
        user,
        token,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get current logged in user
// @route   GET /api/v1/auth/me
// @access  Private
exports.getMe = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);

    res.status(200).json({
      success: true,
      data: user,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update user details
// @route   PUT /api/v1/auth/update
// @access  Private
exports.updateDetails = async (req, res, next) => {
  try {
    const fieldsToUpdate = {
      username: req.body.username,
      phoneNumber: req.body.phoneNumber,
    };

    const user = await User.findByIdAndUpdate(req.user.id, fieldsToUpdate, {
      new: true,
      runValidators: true,
    });

    res.status(200).json({
      success: true,
      data: user,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update password
// @route   PUT /api/v1/auth/updatepassword
// @access  Private
exports.updatePassword = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id).select('+password');

    // Check current password
    if (!(await user.comparePassword(req.body.currentPassword))) {
      return res.status(401).json({
        success: false,
        message: 'Password is incorrect',
      });
    }

    user.password = req.body.newPassword;
    await user.save();

    const token = generateToken(user._id);

    res.status(200).json({
      success: true,
      data: {
        token,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Register/Update FCM token
// @route   POST /api/v1/auth/fcm-token
// @access  Private
exports.registerFCMToken = async (req, res, next) => {
  try {
    const { token, platform } = req.body;

    if (!token) {
      return res.status(400).json({
        success: false,
        message: 'FCM token is required',
      });
    }

    const user = await User.findById(req.user.id);

    // Check if token already exists
    const tokenExists = user.fcmTokens.some(t => t.token === token);

    if (!tokenExists) {
      user.fcmTokens.push({
        token,
        platform: platform || 'android',
      });
      await user.save();
    }

    res.status(200).json({
      success: true,
      message: 'FCM token registered successfully',
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Remove FCM token
// @route   DELETE /api/v1/auth/fcm-token
// @access  Private
exports.removeFCMToken = async (req, res, next) => {
  try {
    const { token } = req.body;

    const user = await User.findById(req.user.id);
    user.fcmTokens = user.fcmTokens.filter(t => t.token !== token);
    await user.save();

    res.status(200).json({
      success: true,
      message: 'FCM token removed successfully',
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Delete user account
// @route   DELETE /api/v1/auth/me
// @access  Private
exports.deleteAccount = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Delete the user account
    await User.findByIdAndDelete(req.user.id);

    res.status(200).json({
      success: true,
      message: 'Account deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};
