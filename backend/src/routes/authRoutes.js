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
} = require('../controllers/authController');
const { protect } = require('../middleware/auth');
const { body } = require('express-validator');
const validate = require('../middleware/validate');

const router = express.Router();

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
router.post('/fcm-token', protect, registerFCMToken);
router.delete('/fcm-token', protect, removeFCMToken);

module.exports = router;
