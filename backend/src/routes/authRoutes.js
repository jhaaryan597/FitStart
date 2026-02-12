const express = require('express');
const {
  register,
  login,
  googleSignIn,
  getMe,
  updateDetails,
  updatePassword,
  registerFCMToken,
  removeFCMToken,
  deleteAccount,
  uploadProfileImage,
} = require('../controllers/authController');
const { protect } = require('../middleware/auth');
const { body } = require('express-validator');
const validate = require('../middleware/validate');
const multer = require('multer');

const router = express.Router();

// Configure multer for file uploads
const upload = multer({
  dest: 'temp/',
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  },
});

// Validation rules
const registerValidation = [
  body('username').trim().isLength({ min: 3 }).withMessage('Username must be at least 3 characters'),
  body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  validate,
];

const loginValidation = [
  body('email').isEmail().normalizeEmail().withMessage('Please provide a valid email'),
  body('password').notEmpty().withMessage('Password is required'),
  validate,
];

const googleSignInValidation = [
  body('idToken').notEmpty().withMessage('Google ID token is required'),
  validate,
];

// Routes
router.post('/google', googleSignInValidation, googleSignIn);
router.post('/register', registerValidation, register);
router.post('/login', loginValidation, login);
router.get('/me', protect, getMe);
router.put('/update', protect, updateDetails);
router.put('/updatepassword', protect, updatePassword);
router.post('/upload-profile-image', protect, upload.single('image'), uploadProfileImage);
router.post('/fcm-token', protect, registerFCMToken);
router.delete('/fcm-token', protect, removeFCMToken);
router.delete('/me', protect, deleteAccount);

module.exports = router;
