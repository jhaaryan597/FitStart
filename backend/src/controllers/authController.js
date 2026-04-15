const User = require('../models/User');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const fs = require('fs/promises');

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

const getJwtExpiry = () => {
  const rawExpire = process.env.JWT_EXPIRE;

  if (rawExpire === undefined || rawExpire === null) {
    return '7d';
  }

  if (typeof rawExpire === 'number') {
    return rawExpire;
  }

  const normalizedExpire = String(rawExpire).trim();

  if (!normalizedExpire) {
    return '7d';
  }

  // If passed as numeric string, convert to seconds
  if (/^\d+$/.test(normalizedExpire)) {
    return Number(normalizedExpire);
  }

  return normalizedExpire;
};

// Generate JWT Token
const generateToken = (id) => {
  try {
    return jwt.sign({ id }, process.env.JWT_SECRET, {
      expiresIn: getJwtExpiry(),
    });
  } catch (error) {
    console.warn(
      `Invalid JWT_EXPIRE value "${process.env.JWT_EXPIRE}". Falling back to 7d.`
    );

    return jwt.sign({ id }, process.env.JWT_SECRET, {
      expiresIn: '7d',
    });
  }
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

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

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
    const fieldsToUpdate = {};
    
    // Only update fields that are provided
    if (req.body.username !== undefined) fieldsToUpdate.username = req.body.username;
    if (req.body.phoneNumber !== undefined) fieldsToUpdate.phoneNumber = req.body.phoneNumber;
    if (req.body.profileImage !== undefined) fieldsToUpdate.profileImage = req.body.profileImage;

    const user = await User.findByIdAndUpdate(req.user.id, fieldsToUpdate, {
      new: true,
      runValidators: true,
    });

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

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

      // Keep only the 10 most recent tokens to prevent unbounded accumulation
      if (user.fcmTokens.length > 10) {
        user.fcmTokens = user.fcmTokens.slice(-10);
      }

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

// @desc    Upload profile image
// @route   POST /api/v1/auth/upload-profile-image
// @access  Private
exports.uploadProfileImage = async (req, res, next) => {
  let uploadedTempPath;

  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'Please upload an image file',
      });
    }

    const file = req.file;
    uploadedTempPath = file.path;

    // Check file type
    if (!file.mimetype.startsWith('image/')) {
      return res.status(400).json({
        success: false,
        message: 'Please upload an image file',
      });
    }

    // Check file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      return res.status(400).json({
        success: false,
        message: 'Image size should be less than 5MB',
      });
    }

    // Upload to Cloudinary
    const { uploadImage, deleteImage } = require('../config/cloudinary');

    // Get current user to check if they have an existing profile image
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Delete old profile image if exists
    if (user.profileImage && user.profileImage.includes('cloudinary')) {
      try {
        // Cloudinary URLs look like: .../upload/v123456/fitstart/profiles/filename.jpg
        // Extract everything after /upload/vXXXXXX/ and strip the file extension
        const match = user.profileImage.match(/\/upload\/(?:v\d+\/)?(.+?)(?:\.[^.]+)?$/);
        if (match && match[1]) {
          await deleteImage(match[1]);
        }
      } catch (deleteError) {
        // Log but don't block the upload if old image cleanup fails
        console.warn('Failed to delete old profile image:', deleteError.message);
      }
    }

    // Upload new image
    const result = await uploadImage(uploadedTempPath, 'fitstart/profiles');

    // Update user profile
    user.profileImage = result.url;
    await user.save();

    res.status(200).json({
      success: true,
      data: {
        profileImage: result.url,
      },
    });
  } catch (error) {
    console.error('Profile image upload error:', error);
    next(error);
  } finally {
    if (uploadedTempPath) {
      try {
        await fs.unlink(uploadedTempPath);
      } catch (cleanupError) {
        // Ignore temp file cleanup errors
      }
    }
  }
};
