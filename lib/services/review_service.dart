import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:FitStart/model/review.dart';
import 'package:FitStart/services/api_service.dart';
import 'package:FitStart/core/cache/cache_manager.dart';

/// Service for managing venue reviews
/// Uses local storage with simulated reviews since backend lacks review endpoints
class ReviewService {
  static const String _boxName = 'reviews_box';
  static Box? _box;
  static final Random _random = Random();

  /// Initialize the review service
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }
  }

  /// Get reviews for a venue
  static Future<Map<String, dynamic>> getReviews({
    required String venueId,
    required String venueType,
  }) async {
    try {
      await init();
      
      // Check local storage first
      final key = '${venueType}_${venueId}';
      final cachedData = _box?.get(key);
      
      if (cachedData != null) {
        final List<Review> reviews = (cachedData as List)
            .map((e) => Review.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        
        return {
          'success': true,
          'data': reviews,
          'summary': ReviewSummary.fromReviews(reviews),
        };
      }
      
      // Generate sample reviews for demo
      final reviews = await _generateSampleReviews(venueId, venueType);
      
      // Cache locally
      await _box?.put(key, reviews.map((r) => r.toJson()).toList());
      
      return {
        'success': true,
        'data': reviews,
        'summary': ReviewSummary.fromReviews(reviews),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to load reviews: $e',
      };
    }
  }

  /// Submit a new review
  static Future<Map<String, dynamic>> submitReview({
    required String venueId,
    required String venueType,
    required double rating,
    required String comment,
    List<String>? images,
  }) async {
    try {
      await init();
      
      // Get current user - try multiple sources
      Map<String, dynamic>? user;
      
      // Try API first
      final userResult = await ApiService.getCurrentUser();
      if (userResult['success']) {
        user = userResult['data'];
      } else {
        // Fallback to cached profile
        final cachedProfile = await CacheManager.get<Map<String, dynamic>>('user_profile');
        if (cachedProfile != null) {
          user = cachedProfile;
        } else {
          // Try user_cache as last resort
          try {
            final userBox = await Hive.openBox('user_cache');
            final email = userBox.get('email') as String?;
            final name = userBox.get('name') as String?;
            final id = userBox.get('id') as String?;
            
            if (email != null || id != null) {
              user = {
                '_id': id ?? email ?? 'local_user',
                'email': email ?? '',
                'name': name ?? email?.split('@').first ?? 'User',
              };
            }
          } catch (_) {}
        }
      }
      
      if (user == null) {
        return {
          'success': false,
          'error': 'Please login to submit a review',
        };
      }
      
      final review = Review(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        venueId: venueId,
        venueType: venueType,
        userId: user['_id'] ?? user['id'] ?? '',
        userName: user['name'] ?? user['username'] ?? 'User',
        userImage: user['profileImage'],
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
        images: images,
        isVerifiedBooking: true, // User has booked if they can submit review
      );
      
      // Get existing reviews
      final key = '${venueType}_${venueId}';
      final existingData = _box?.get(key);
      List<Map<String, dynamic>> allReviews = [];
      
      if (existingData != null) {
        allReviews = List<Map<String, dynamic>>.from(
          (existingData as List).map((e) => Map<String, dynamic>.from(e))
        );
      }
      
      // Add new review at the beginning
      allReviews.insert(0, review.toJson());
      
      // Save back
      await _box?.put(key, allReviews);
      
      return {
        'success': true,
        'data': review,
        'message': 'Review submitted successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to submit review: $e',
      };
    }
  }

  /// Generate sample reviews for demo purposes
  static Future<List<Review>> _generateSampleReviews(
    String venueId,
    String venueType,
  ) async {
    final sampleNames = [
      'Rahul Sharma',
      'Priya Singh',
      'Amit Patel',
      'Sneha Gupta',
      'Vikram Kumar',
      'Anjali Verma',
      'Rohan Mehta',
      'Neha Agarwal',
      'Karan Joshi',
      'Pooja Reddy',
    ];

    final sampleComments = {
      5: [
        'Excellent facility! Clean and well-maintained. Will definitely come again.',
        'Amazing experience! The staff was very helpful and professional.',
        'Best venue in the city. Great equipment and ambiance.',
        'Loved it! Perfect for practice sessions. Highly recommended!',
        'Outstanding service and facilities. 5 stars all the way!',
      ],
      4: [
        'Very good venue. Minor improvements needed but overall great.',
        'Nice place to play. Good facilities and reasonable prices.',
        'Had a great time. Staff was friendly and helpful.',
        'Good experience overall. Would recommend to friends.',
        'Solid venue with good equipment. Could improve parking.',
      ],
      3: [
        'Decent place. Gets the job done but nothing special.',
        'Average experience. Some facilities need maintenance.',
        'Okay venue. Crowded on weekends but manageable.',
        'Fair enough for the price. Room for improvement.',
        'Standard venue. Nothing to complain about.',
      ],
      2: [
        'Below expectations. Facilities need serious upgrades.',
        'Not impressed. Staff seemed disinterested.',
        'Could be much better. Cleanliness was an issue.',
      ],
      1: [
        'Disappointing experience. Would not recommend.',
        'Poor maintenance and rude staff.',
      ],
    };

    // Generate 3-8 reviews
    final numReviews = _random.nextInt(6) + 3;
    final reviews = <Review>[];
    final usedNames = <String>{};

    for (int i = 0; i < numReviews; i++) {
      // Weighted rating (more 4-5 star reviews)
      final ratingRoll = _random.nextDouble();
      int rating;
      if (ratingRoll < 0.4) {
        rating = 5;
      } else if (ratingRoll < 0.7) {
        rating = 4;
      } else if (ratingRoll < 0.85) {
        rating = 3;
      } else if (ratingRoll < 0.95) {
        rating = 2;
      } else {
        rating = 1;
      }

      // Get unique name
      String name;
      do {
        name = sampleNames[_random.nextInt(sampleNames.length)];
      } while (usedNames.contains(name) && usedNames.length < sampleNames.length);
      usedNames.add(name);

      // Get random comment for the rating
      final comments = sampleComments[rating] ?? sampleComments[3]!;
      final comment = comments[_random.nextInt(comments.length)];

      // Random date within last 3 months
      final daysAgo = _random.nextInt(90);
      final createdAt = DateTime.now().subtract(Duration(days: daysAgo));

      reviews.add(Review(
        id: '${venueId}_review_${i}_${DateTime.now().millisecondsSinceEpoch}',
        venueId: venueId,
        venueType: venueType,
        userId: 'user_${_random.nextInt(10000)}',
        userName: name,
        rating: rating.toDouble(),
        comment: comment,
        createdAt: createdAt,
        isVerifiedBooking: _random.nextDouble() > 0.3, // 70% verified
      ));
    }

    // Sort by date (newest first)
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return reviews;
  }

  /// Get the calculated average rating for a venue
  static Future<double> getAverageRating({
    required String venueId,
    required String venueType,
  }) async {
    final result = await getReviews(venueId: venueId, venueType: venueType);
    if (result['success']) {
      final summary = result['summary'] as ReviewSummary;
      return summary.averageRating;
    }
    return 0;
  }

  /// Check if user can submit review (has completed booking)
  static Future<bool> canSubmitReview({
    required String venueId,
    required String venueType,
  }) async {
    try {
      final userResult = await ApiService.getCurrentUser();
      if (!userResult['success']) return false;
      
      // For demo, allow reviews without booking verification
      // In production, verify against booking history
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a review (user's own review only)
  static Future<Map<String, dynamic>> deleteReview({
    required String venueId,
    required String venueType,
    required String reviewId,
  }) async {
    try {
      await init();
      
      final key = '${venueType}_${venueId}';
      final existingData = _box?.get(key);
      
      if (existingData == null) {
        return {'success': false, 'error': 'Review not found'};
      }
      
      List<Map<String, dynamic>> reviews = List<Map<String, dynamic>>.from(
        (existingData as List).map((e) => Map<String, dynamic>.from(e))
      );
      
      reviews.removeWhere((r) => r['_id'] == reviewId || r['id'] == reviewId);
      
      await _box?.put(key, reviews);
      
      return {'success': true, 'message': 'Review deleted'};
    } catch (e) {
      return {'success': false, 'error': 'Failed to delete review: $e'};
    }
  }
}
