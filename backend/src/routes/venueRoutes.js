const express = require('express');
const { body } = require('express-validator');
const {
  getVenues,
  getVenue,
  createVenue,
  updateVenue,
  deleteVenue,
  toggleFavorite,
  getFavorites,
  getNearbyVenues,
} = require('../controllers/venueController');
const { protect, authorize } = require('../middleware/auth');
const validate = require('../middleware/validate');

const router = express.Router();

const createVenueValidation = [
  body('name').trim().notEmpty().withMessage('Venue name is required'),
  body('address').trim().notEmpty().withMessage('Address is required'),
  body('phoneNumber').trim().notEmpty().withMessage('Phone number is required'),
  body('openTime').trim().notEmpty().withMessage('Opening time is required'),
  body('closeTime').trim().notEmpty().withMessage('Closing time is required'),
  body('pricing.hourlyRate').isNumeric().withMessage('Hourly rate must be a number'),
  body('category').isIn(['football', 'basketball', 'badminton', 'tennis', 'volleyball', 'cricket', 'swimming', 'gym', 'other'])
    .withMessage('Invalid category'),
  validate,
];

router.route('/')
  .get(getVenues)
  .post(protect, authorize('admin', 'venue_owner'), createVenueValidation, createVenue);

router.get('/favorites', protect, getFavorites);
router.get('/nearby', getNearbyVenues);

router.route('/:id')
  .get(getVenue)
  .put(protect, authorize('admin', 'venue_owner'), updateVenue)
  .delete(protect, authorize('admin', 'venue_owner'), deleteVenue);

router.post('/:id/favorite', protect, toggleFavorite);

module.exports = router;
