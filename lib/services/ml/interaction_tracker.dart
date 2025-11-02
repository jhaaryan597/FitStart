import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks user interactions for Machine Learning recommendation system.
///
/// This service logs user behavior (views, favorites, bookings) to the
/// user_interactions table, which is then used by the KNN recommender
/// for personalized recommendations.
class InteractionTracker {
  static final _supabase = Supabase.instance.client;

  /// Track when user views a venue detail screen
  static Future<void> trackView({
    required String userId,
    required String venueId,
    required String venueType,
  }) async {
    return _trackInteraction(
      userId: userId,
      venueId: venueId,
      venueType: venueType,
      interactionType: 'view',
      score: 1,
    );
  }

  /// Track when user favorites a venue
  static Future<void> trackFavorite({
    required String userId,
    required String venueId,
    required String venueType,
  }) async {
    return _trackInteraction(
      userId: userId,
      venueId: venueId,
      venueType: venueType,
      interactionType: 'favorite',
      score: 3,
    );
  }

  /// Track when user unfavorites a venue
  static Future<void> trackUnfavorite({
    required String userId,
    required String venueId,
    required String venueType,
  }) async {
    return _trackInteraction(
      userId: userId,
      venueId: venueId,
      venueType: venueType,
      interactionType: 'unfavorite',
      score: -2,
    );
  }

  /// Track when user books a venue
  static Future<void> trackBooking({
    required String userId,
    required String venueId,
    required String venueType,
  }) async {
    return _trackInteraction(
      userId: userId,
      venueId: venueId,
      venueType: venueType,
      interactionType: 'book',
      score: 5,
    );
  }

  /// Internal method to track interaction
  static Future<void> _trackInteraction({
    required String userId,
    required String venueId,
    required String venueType,
    required String interactionType,
    required int score,
  }) async {
    try {
      await _supabase.from('user_interactions').insert({
        'user_id': userId,
        'venue_id': venueId,
        'venue_type': venueType,
        'interaction_type': interactionType,
        'interaction_score': score,
      });
    } catch (e) {
      print('Error tracking interaction: $e');
      // Don't throw - tracking should be non-blocking
    }
  }

  /// Get user's interaction history for analysis
  static Future<List<Map<String, dynamic>>> getUserInteractions({
    required String userId,
    String? venueType,
    int limit = 50,
  }) async {
    try {
      final response = venueType != null
          ? await _supabase
              .from('user_interactions')
              .select()
              .eq('user_id', userId)
              .eq('venue_type', venueType)
              .order('created_at', ascending: false)
              .limit(limit)
          : await _supabase
              .from('user_interactions')
              .select()
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching user interactions: $e');
      return [];
    }
  }

  /// Get venue popularity based on all user interactions
  static Future<Map<String, int>> getVenuePopularity({
    String? venueType,
    int limit = 10,
  }) async {
    try {
      final response = venueType != null
          ? await _supabase
              .from('user_interactions')
              .select('venue_id, interaction_score')
              .eq('venue_type', venueType)
          : await _supabase
              .from('user_interactions')
              .select('venue_id, interaction_score');

      // Aggregate scores per venue
      final popularity = <String, int>{};
      for (final row in response) {
        final venueId = row['venue_id'] as String;
        final score = row['interaction_score'] as int;
        popularity[venueId] = (popularity[venueId] ?? 0) + score;
      }

      // Sort by score and return top venues
      final sortedEntries = popularity.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return Map.fromEntries(sortedEntries.take(limit));
    } catch (e) {
      print('Error fetching venue popularity: $e');
      return {};
    }
  }

  /// Get similar users based on interaction patterns (Collaborative Filtering)
  static Future<List<Map<String, dynamic>>> getSimilarUsers({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final response = await _supabase.rpc('get_similar_users', params: {
        'target_user_id': userId,
        'limit_count': limit,
      });

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching similar users: $e');
      return [];
    }
  }

  /// Get collaborative filtering recommendations
  static Future<List<Map<String, dynamic>>> getCollaborativeRecommendations({
    required String userId,
    String? venueType,
    int limit = 10,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_collaborative_recommendations',
        params: {
          'target_user_id': userId,
          'venue_type_filter': venueType,
          'limit_count': limit,
        },
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching collaborative recommendations: $e');
      return [];
    }
  }

  /// Clear old interactions (cleanup for privacy/performance)
  static Future<void> clearOldInteractions({
    required String userId,
    int daysToKeep = 90,
  }) async {
    try {
      final cutoffDate =
          DateTime.now().subtract(Duration(days: daysToKeep)).toIso8601String();

      await _supabase
          .from('user_interactions')
          .delete()
          .eq('user_id', userId)
          .lt('created_at', cutoffDate);
    } catch (e) {
      print('Error clearing old interactions: $e');
    }
  }
}
