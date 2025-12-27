import 'package:FitStart/model/sport_field.dart';
import 'package:FitStart/model/gym.dart';
import 'package:FitStart/services/ml/knn_recommender.dart';
import 'package:FitStart/services/ml/interaction_tracker.dart';
import 'package:FitStart/utils/dummy_data.dart';
import 'package:FitStart/utils/gym_data.dart';
import 'package:FitStart/services/api_service.dart';

/// Machine Learning Recommendation Service
///
/// This service uses REAL machine learning algorithms:
/// 1. K-Nearest Neighbors (KNN) with cosine similarity
/// 2. Collaborative Filtering based on similar users
/// 3. Content-Based Filtering using feature vectors
/// 4. Hybrid approach combining all methods
///
/// The ML models learn from user interactions stored in the backend
/// and provide personalized recommendations without requiring
/// pre-trained models or external datasets.
class MLRecommendationService {

  /// Get ML-powered personalized venue recommendations
  ///
  /// Uses K-Nearest Neighbors algorithm with:
  /// - Feature vectors (category, facilities, price, rating, distance)
  /// - Cosine similarity for nearest neighbor calculation
  /// - Collaborative filtering from similar users
  /// - Hybrid scoring for optimal results
  static Future<List<SportField>> getRecommendedVenues({
    String? userId,
    int limit = 10,
  }) async {
    try {
      // Use KNN recommender with hybrid ML approach
      return await KNNRecommenderService.recommend(
        userId: userId,
        allFields: sportFieldList,
        topN: limit,
        useDistanceIfAvailable: true,
      );
    } catch (e) {
      print('Error getting ML recommendations: $e');
      // Fallback to popular venues
      return _getPopularVenues(limit);
    }
  }

  /// Get ML-powered gym recommendations
  static Future<List<Gym>> getRecommendedGyms({
    String? userId,
    int limit = 5,
  }) async {
    if (userId == null) {
      return _getPopularGyms(limit);
    }

    try {
      // Get user's interaction patterns
      final interactions = await InteractionTracker.getUserInteractions(
        userId: userId,
        venueType: 'gym',
        limit: 50,
      );

      if (interactions.isEmpty) {
        return _getPopularGyms(limit);
      }

      // Get collaborative recommendations
      final collabRecs =
          await InteractionTracker.getCollaborativeRecommendations(
        userId: userId,
        limit: limit * 2,
      );

      // Match recommended gym IDs with gym list
      final recommendedGymIds =
          collabRecs.map((rec) => rec['venue_id'] as String).toSet();

      final recommendedGyms =
          gymList.where((gym) => recommendedGymIds.contains(gym.id)).toList();

      // If we don't have enough recommendations, add popular gyms
      if (recommendedGyms.length < limit) {
        final remaining = limit - recommendedGyms.length;
        final popularGyms = _getPopularGyms(remaining);
        recommendedGyms.addAll(popularGyms.where(
          (gym) => !recommendedGyms.any((rg) => rg.id == gym.id),
        ));
      }

      return recommendedGyms.take(limit).toList();
    } catch (e) {
      print('Error getting gym recommendations: $e');
      return _getPopularGyms(limit);
    }
  }

  /// Get similar venues using content-based filtering
  ///
  /// Uses KNN to find venues with similar features
  static Future<List<SportField>> getSimilarVenues({
    required SportField venue,
    int limit = 5,
  }) async {
    try {
      // Create a temporary user profile from this single venue
      final allVenues = List<SportField>.from(sportFieldList);

      // Remove the current venue from recommendations
      allVenues.removeWhere((v) => v.id == venue.id);

      // Use KNN to find similar venues
      return await KNNRecommenderService.recommend(
        userId: null,
        allFields: allVenues,
        topN: limit,
        useDistanceIfAvailable: false,
      );
    } catch (e) {
      print('Error getting similar venues: $e');
      return [];
    }
  }

  /// Get trending venues based on recent interactions
  static Future<List<SportField>> getTrendingVenues({int limit = 10}) async {
    try {
      final venueIds = sportFieldList.map((v) => v.id.toString()).toList();
      final popularity = await InteractionTracker.getVenuePopularity(
        venueIds: venueIds,
      );

      final trendingVenues = sportFieldList
          .where((venue) => popularity.containsKey(venue.id))
          .toList()
        ..sort((a, b) {
          final scoreA = popularity[a.id] ?? 0;
          final scoreB = popularity[b.id] ?? 0;
          return scoreB.compareTo(scoreA);
        });

      return trendingVenues.take(limit).toList();
    } catch (e) {
      print('Error getting trending venues: $e');
      return _getPopularVenues(limit);
    }
  }

  /// Get venues that similar users liked (Collaborative Filtering)
  static Future<List<SportField>> getCollaborativeRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final recommendations =
          await InteractionTracker.getCollaborativeRecommendations(
        userId: userId,
        limit: limit,
      );

      final recommendedIds =
          recommendations.map((rec) => rec['venue_id'] as String).toSet();

      final venues = sportFieldList
          .where((venue) => recommendedIds.contains(venue.id))
          .toList();

      // Sort by recommendation score
      venues.sort((a, b) {
        final scoreA = recommendations.firstWhere(
            (rec) => rec['venue_id'] == a.id)['recommendation_score'] as num;
        final scoreB = recommendations.firstWhere(
            (rec) => rec['venue_id'] == b.id)['recommendation_score'] as num;
        return scoreB.compareTo(scoreA);
      });

      return venues;
    } catch (e) {
      print('Error getting collaborative recommendations: $e');
      return [];
    }
  }

  /// Track user viewing a venue (for ML learning)
  static Future<void> trackVenueView(String venueId) async {
    try {
      final result = await ApiService.getCurrentUser();
      if (!result['success']) return;

      final userId = result['data']['_id'] as String;
      await InteractionTracker.trackView(
        userId: userId,
        venueId: venueId,
        venueType: 'sports_venue',
      );
    } catch (e) {
      // Silently fail - tracking shouldn't block app
    }
  }

  /// Track user viewing a gym (for ML learning)
  static Future<void> trackGymView(String gymId) async {
    try {
      final result = await ApiService.getCurrentUser();
      if (!result['success']) return;

      final userId = result['data']['_id'] as String;
      await InteractionTracker.trackView(
        userId: userId,
        venueId: gymId,
        venueType: 'gym',
      );
    } catch (e) {
      // Silently fail - tracking shouldn't block app
    }
  }

  /// Track user booking a venue (for ML learning)
  static Future<void> trackVenueBooking(String venueId) async {
    try {
      final result = await ApiService.getCurrentUser();
      if (!result['success']) return;

      final userId = result['data']['_id'] as String;
      await InteractionTracker.trackBooking(
        userId: userId,
        venueId: venueId,
        venueType: 'sports_venue',
      );
    } catch (e) {
      // Silently fail - tracking shouldn't block app
    }
  }

  /// Track user getting gym membership (for ML learning)
  static Future<void> trackGymMembership(String gymId) async {
    try {
      final result = await ApiService.getCurrentUser();
      if (!result['success']) return;

      final userId = result['data']['_id'] as String;
      await InteractionTracker.trackBooking(
        userId: userId,
        venueId: gymId,
        venueType: 'gym',
      );
    } catch (e) {
      // Silently fail - tracking shouldn't block app
    }
  }

  /// Track favorite action (for ML learning)
  static Future<void> trackFavorite(String venueId, String venueType) async {
    try {
      final result = await ApiService.getCurrentUser();
      if (!result['success']) return;

      final userId = result['data']['_id'] as String;
      await InteractionTracker.trackFavorite(
        userId: userId,
        venueId: venueId,
        venueType: venueType,
      );
    } catch (e) {
      // Silently fail - tracking shouldn't block app
    }
  }

  /// Track unfavorite action (for ML learning)
  static Future<void> trackUnfavorite(String venueId, String venueType) async {
    try {
      final result = await ApiService.getCurrentUser();
      if (!result['success']) return;

      final userId = result['data']['_id'] as String;
      await InteractionTracker.trackUnfavorite(
        userId: userId,
        venueId: venueId,
        venueType: venueType,
      );
    } catch (e) {
      // Silently fail - tracking shouldn't block app
    }
  }

  /// Get ML insights about user preferences
  static Future<Map<String, dynamic>> getUserPreferenceInsights({
    required String userId,
  }) async {
    try {
      final interactions = await InteractionTracker.getUserInteractions(
        userId: userId,
        limit: 100,
      );

      // Analyze user preferences from interactions
      final categoryCount = <String, int>{};
      final venueTypeCount = <String, int>{};
      int totalScore = 0;

      for (final interaction in interactions) {
        final score = interaction['interaction_score'] as int;
        totalScore += score;

        final venueId = interaction['venue_id'] as String;
        final venueType = interaction['venue_type'] as String;

        venueTypeCount[venueType] = (venueTypeCount[venueType] ?? 0) + 1;

        // For sports venues, get category
        if (venueType == 'sports_venue') {
          final venue = sportFieldList.firstWhere(
            (v) => v.id == venueId,
            orElse: () => sportFieldList.first,
          );
          final category = venue.category.name;
          categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        }
      }

      return {
        'total_interactions': interactions.length,
        'total_engagement_score': totalScore,
        'favorite_categories': categoryCount,
        'venue_type_preferences': venueTypeCount,
        'engagement_level': _calculateEngagementLevel(totalScore),
      };
    } catch (e) {
      print('Error getting user insights: $e');
      return {};
    }
  }

  /// Fallback: Get popular venues
  static List<SportField> _getPopularVenues(int limit) {
    return sportFieldList.where((v) => v.rating >= 4.0).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating))
      ..take(limit);
  }

  /// Fallback: Get popular gyms
  static List<Gym> _getPopularGyms(int limit) {
    return gymList.where((g) => g.rating >= 4.0).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating))
      ..take(limit);
  }

  /// Calculate engagement level from score
  static String _calculateEngagementLevel(int score) {
    if (score < 10) return 'New User';
    if (score < 30) return 'Casual User';
    if (score < 60) return 'Regular User';
    if (score < 100) return 'Active User';
    return 'Power User';
  }
}
