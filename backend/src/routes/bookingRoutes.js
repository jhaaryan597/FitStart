const express = require('express');
const {
  getBookings,
  getBooking,
  createBooking,
  verifyPayment,
  cancelBooking,
  getAvailableSlots,
} = require('../controllers/bookingController');
const { protect } = require('../middleware/auth');

const router = express.Router();

router.route('/')
  .get(protect, getBookings)
  .post(protect, createBooking);

router.get('/available-slots/:venueId', getAvailableSlots);

router.route('/:id')
  .get(protect, getBooking);

router.post('/:id/verify-payment', protect, verifyPayment);
router.put('/:id/cancel', protect, cancelBooking);

module.exports = router;
