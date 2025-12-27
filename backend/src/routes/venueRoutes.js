const express = require('express');
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

const router = express.Router();

router.route('/')
  .get(getVenues)
  .post(protect, authorize('admin', 'venue_owner'), createVenue);

router.get('/favorites', protect, getFavorites);
router.get('/nearby', getNearbyVenues);

router.route('/:id')
  .get(getVenue)
  .put(protect, authorize('admin', 'venue_owner'), updateVenue)
  .delete(protect, authorize('admin', 'venue_owner'), deleteVenue);

router.post('/:id/favorite', protect, toggleFavorite);

module.exports = router;
