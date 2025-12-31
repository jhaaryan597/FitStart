import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// Tracks user interactions for Machine Learning recommendation system.
///
/// This service logs user behavior (views, favorites, bookings) to the
/// backend API, which is then used by the KNN recommender
/// for personalized recommendations.
class InteractionTracker {
  static const String _apiBaseUrl = 'https://fitstart-backend-production.up.railway.app/api/v1';

  /// Track when user views a venue detail screen
  static Future<void> trackView({
    required String userId,
    required String venueId,
    required String venueType,
  }) async {
    try {
      final authBox = await Hive.openBox('auth');
      final jwtToken = authBox.get('jwt_token') as String?;
      
      if (jwtToken != null) {
        await http.post(
          Uri.parse('$_apiBaseUrl/ml/interactions/view'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
          body: jsonEncode({
            'userId': userId,
            'venueId': venueId,
            'venueType': venueType,
            'action': 'view',
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );
      }
      
      if (kDebugMode) {
        print('✅ Track view: User $userId viewed $venueType $venueId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error tracking view: $e');
      }
    }
  }

  /// Track when user adds venue to favorites
  static Future<void> trackFavorite({
    required String userId,
    required String venueId,
    required String venueType,
  }) async {
    try {
      final authBox = await Hive.openBox('auth');
      final jwtToken = authBox.get('jwt_token') as String?;
      
      if (jwtToken != null) {
        await http.post(
          Uri.parse('$_apiBaseUrl/ml/interactions/favorite'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
          body: jsonEncode({
            'userId': userId,
            'venueId': venueId,
            'venueType': venueType,
            'action': 'favorite',
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );
      }
      
      if (kDebugMode) {
        print('✅ Track favorite: User $userId favorited $venueType $venueId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error tracking favorite: $e');
      }
    }
  }

  /// Track when user removes venue from favorites
  static Future<void> trackUnfavorite({
    required String userId,
    required String venueId,
    required String venueType,
  }) async {
    // TODO: Implement backend API call
    if (kDebugMode) {
      print('Track unfavorite: User $userId unfavorited $venueType $venueId');
    }
  }

  /// Track when user makes a booking
  static Future<void> trackBooking({
    required String userId,
    required String venueId,
    required String venueType,
    double? price,
  }) async {
    try {
      final authBox = await Hive.openBox('auth');
      final jwtToken = authBox.get('jwt_token') as String?;
      
      if (jwtToken != null) {
        await http.post(
          Uri.parse('$_apiBaseUrl/ml/interactions/booking'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
          body: jsonEncode({
            'userId': userId,
            'venueId': venueId,
            'venueType': venueType,
            'action': 'booking',
            'price': price,
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );
      }
      
      if (kDebugMode) {
        print('✅ Track booking: User $userId booked $venueType $venueId for \$$price');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error tracking booking: $e');
      }
    }
  }

  /// Track when user searches for venues
  static Future<void> trackSearch({
    required String userId,
    required String query,
    String? category,
  }) async {
    // TODO: Implement backend API call
    if (kDebugMode) {
      print('Track search: User $userId searched for "$query" in category $category');
    }
  }

  /// Get user's interaction history for analysis
  static Future<List<Map<String, dynamic>>> getUserInteractions({
    required String userId,
    String? venueType,
    int limit = 50,
  }) async {
    // TODO: Implement backend API call
    if (kDebugMode) {
      print('Get interactions for user $userId (venueType: $venueType, limit: $limit)');
    }
    return [];
  }

  /// Get similar users based on interaction patterns
  static Future<List<String>> getSimilarUsers({
    required String userId,
    int limit = 10,
  }) async {
    // TODO: Implement backend API call
    if (kDebugMode) {
      print('Get similar users for $userId (limit: $limit)');
    }
    return [];
  }

  /// Get popular venues based on all user interactions
  static Future<List<Map<String, dynamic>>> getPopularVenues({
    String? venueType,
    int limit = 10,
  }) async {
    // TODO: Implement backend API call
    if (kDebugMode) {
      print('Get popular venues (venueType: $venueType, limit: $limit)');
    }
    return [];
  }

  /// Get collaborative filtering recommendations
  static Future<List<Map<String, dynamic>>> getCollaborativeRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    // TODO: Implement backend API call
    if (kDebugMode) {
      print('Get collaborative recommendations for user $userId (limit: $limit)');
    }
    return [];
  }

  /// Get venue popularity scores
  static Future<Map<String, double>> getVenuePopularity({
    required List<String> venueIds,
  }) async {
    // TODO: Implement backend API call
    if (kDebugMode) {
      print('Get popularity for ${venueIds.length} venues');
    }
    return {};
  }
}
