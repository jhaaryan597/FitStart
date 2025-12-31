import 'dart:math' as math;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:FitStart/model/sport_field.dart';
import 'package:FitStart/utils/dummy_data.dart';
import 'package:FitStart/utils/location_service.dart';

// Backend API URL
const String apiBaseUrl = 'https://fitstart-backend-production.up.railway.app/api/v1';

/// On-device kNN-style recommender using cosine similarity over feature vectors.
/// Features: one-hot category, one-hot facilities, normalized price, rating,
/// and optional normalized distance if available.
class KNNRecommenderService {
  /// Recommend topN venues using REAL K-Nearest Neighbors machine learning.
  ///
  /// This uses:
  /// 1. Content-based filtering: Feature vectors with cosine similarity
  /// 2. Collaborative filtering: Similar users based on interaction patterns
  /// 3. Hybrid scoring: Combines both approaches for better recommendations
  ///
  /// If a userId is provided with booking/interaction history, recommendations
  /// are personalized. Otherwise, falls back to popularity-based ranking.
  static Future<List<SportField>> recommend({
    String? userId,
    List<SportField>? allFields,
    int topN = 5,
    bool useDistanceIfAvailable = true,
  }) async {
    final fields = (allFields == null || allFields.isEmpty)
        ? List<SportField>.from(sportFieldList)
        : allFields;

    if (fields.length <= 1) return fields;

    final dict = _Dictionaries.fromFields(fields);
    List<String> bookedFieldIds = [];
    List<String> interactedFieldIds = [];

    if (userId != null) {
      try {
        // Get JWT token from Hive
        final authBox = await Hive.openBox('auth');
        final jwtToken = authBox.get('jwt_token') as String?;
        
        if (jwtToken != null) {
          // Get user bookings from backend API
          final bookingsResponse = await http.get(
            Uri.parse('$apiBaseUrl/bookings'),
            headers: {
              'Authorization': 'Bearer $jwtToken',
            },
          );

          if (bookingsResponse.statusCode == 200) {
            final bookingsData = jsonDecode(bookingsResponse.body);
            if (bookingsData['success'] == true) {
              bookedFieldIds = (bookingsData['data'] as List)
                  .map((booking) => booking['venue'] as String)
                  .toList();
            }
          }

          // Get user interactions/favorites from backend API
          final userResponse = await http.get(
            Uri.parse('$apiBaseUrl/auth/me'),
            headers: {
              'Authorization': 'Bearer $jwtToken',
            },
          );

          if (userResponse.statusCode == 200) {
            final userData = jsonDecode(userResponse.body);
            if (userData['success'] == true) {
              interactedFieldIds = List<String>.from(
                userData['data']['favorites'] ?? []
              );
            }
          }
        }
      } catch (e) {
        // Handle error, e.g., log it. Fallback to cold start.
        print('ML Error fetching user history: $e');
      }
    }

    // Enhanced Cold Start: Intelligent recommendations for new users
    if (bookedFieldIds.isEmpty && interactedFieldIds.isEmpty) {
      return await _getGeneralizedRecommendations(fields, topN, userId);
    }

    // Combine booked and interacted venues for user profile
    final allUserFieldIds = {...bookedFieldIds, ...interactedFieldIds}.toList();
    final userFields =
        fields.where((f) => allUserFieldIds.contains(f.id)).toList();

    if (userFields.isEmpty) {
      // Fallback if field IDs don't match any known fields.
      final sorted = List<SportField>.from(fields)
        ..sort((a, b) {
          final r = b.rating.compareTo(a.rating);
          return r != 0 ? r : a.price.compareTo(b.price);
        });
      return sorted.take(topN).toList();
    }

    final includeDistance =
        useDistanceIfAvailable && fields.any((f) => f.distanceKm != null);

    // ========== K-NEAREST NEIGHBORS ALGORITHM ==========
    // Step 1: Create user profile vector from interaction history
    // This represents the user's preferences in the feature space
    final userProfileVector =
        _createProfileVector(userFields, dict, includeDistance);

    // Step 2: Try to get collaborative filtering recommendations from backend
    Map<String, double> collaborativeScores = {};
    if (userId != null) {
      try {
        final authBox = await Hive.openBox('auth');
        final jwtToken = authBox.get('jwt_token') as String?;
        
        if (jwtToken != null) {
          // Call backend API for ML recommendations (if implemented)
          final mlResponse = await http.get(
            Uri.parse('$apiBaseUrl/venues/recommendations'),
            headers: {
              'Authorization': 'Bearer $jwtToken',
            },
          );

          if (mlResponse.statusCode == 200) {
            final mlData = jsonDecode(mlResponse.body);
            if (mlData['success'] == true) {
              for (final rec in (mlData['data'] as List)) {
                collaborativeScores[rec['venueId'] as String] =
                    (rec['score'] as num).toDouble();
              }
            }
          }
        }
      } catch (e) {
        print('Collaborative filtering error: $e');
      }
    }

    // Step 3: Calculate cosine similarity for all venues
    final scored = <_Scored<SportField>>[];
    for (final f in fields) {
      // Don't recommend items the user has already interacted with
      if (allUserFieldIds.contains(f.id)) continue;

      // Content-based similarity using KNN
      final v = _vectorize(f, dict, includeDistance: includeDistance);
      final contentSimilarity = _cosineSimilarity(userProfileVector, v);

      // Collaborative filtering score (if available)
      final collaborativeScore = collaborativeScores[f.id] ?? 0.0;

      // Hybrid scoring: Combine content-based and collaborative filtering
      // Weight: 60% content-based, 40% collaborative
      double mlScore = (0.6 * contentSimilarity) + (0.4 * collaborativeScore);

      // Additional quality signals (not just heuristics, but ML features)
      final ratingBoost = (f.rating - 3.5).clamp(0, 1.5);
      final pricePenalty = (f.price > dict.priceP75) ? 0.2 : 0.0;

      // Final score combines ML similarity with quality signals
      final score = mlScore + 0.05 * ratingBoost - pricePenalty;

      scored.add(_Scored(item: f, score: score));
    }

    // Step 4: Sort by K-NN similarity scores and return top N
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.take(topN).map((e) => e.item).toList();
  }

  /// Create an aggregated feature vector from a list of fields.
  static List<double> _createProfileVector(
      List<SportField> fields, _Dictionaries d, bool includeDistance) {
    if (fields.isEmpty) return [];
    var profile = List<double>.filled(
        _vectorize(fields.first, d, includeDistance: includeDistance).length,
        0.0);

    for (final field in fields) {
      final vec = _vectorize(field, d, includeDistance: includeDistance);
      for (int i = 0; i < profile.length; i++) {
        profile[i] += vec[i];
      }
    }

    // Average the vector
    for (int i = 0; i < profile.length; i++) {
      profile[i] /= fields.length;
    }
    return profile;
  }

  /// Build feature vector for a field.
  static List<double> _vectorize(
    SportField f,
    _Dictionaries d, {
    required bool includeDistance,
  }) {
    final vec = <double>[];

    // Category one-hot
    final cat = List<double>.filled(d.categories.length, 0);
    final ci = d.categories[f.category.name] ?? 0;
    if (ci >= 0 && ci < cat.length) cat[ci] = 1;
    vec.addAll(cat);

    // Facilities one-hot
    final fac = List<double>.filled(d.facilities.length, 0);
    for (final facility in f.facilities) {
      final idx = d.facilities[facility.name];
      if (idx != null && idx >= 0 && idx < fac.length) fac[idx] = 1;
    }
    vec.addAll(fac);

    // Normalized numeric features
    final priceRange = (d.priceMax - d.priceMin).abs();
    final priceNorm =
        priceRange == 0 ? 0 : (f.price - d.priceMin) / (priceRange + 1e-9);
    final ratingNorm = (f.rating.clamp(0, 5)) / 5.0;
    vec.addAll([priceNorm.toDouble(), ratingNorm.toDouble()]);

    if (includeDistance) {
      final dist = f.distanceKm ?? d.distP95;
      final distNorm = d.distP95 == 0 ? 0 : dist / (d.distP95 + 1e-9);
      vec.add((distNorm.clamp(0, 1.0)) as double);
    }

    return vec;
  }

  static double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0, na = 0, nb = 0;
    final len = math.min(a.length, b.length);
    for (int i = 0; i < len; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    if (na == 0 || nb == 0) return 0;
    return dot / (math.sqrt(na) * math.sqrt(nb));
  }

  /// Intelligent generalized recommendations for new users
  /// Uses location proximity, ratings, popularity, and variety
  static Future<List<SportField>> _getGeneralizedRecommendations(
      List<SportField> fields, int topN, String? userId) async {
    final scored = <_Scored<SportField>>[];
    
    // Get user's location for distance-based recommendations
    final userPosition = LocationService.getLastKnownPosition();
    
    // Calculate diverse category representation
    final categoryCount = <String, int>{};
    final maxPerCategory = (topN / 3).ceil(); // Max venues per category for diversity
    
    for (final field in fields) {
      double score = 0.0;
      
      // 1. Rating quality (40% weight) - prioritize highly rated venues
      final ratingScore = (field.rating - 1) / 4; // Normalize 1-5 to 0-1
      score += 0.4 * ratingScore;
      
      // 2. Location proximity (30% weight) - prefer nearby venues if location available
      if (userPosition != null) {
        field.distanceKm ??= LocationService.distanceInKm(
          userPosition.latitude,
          userPosition.longitude,
          field.latitude,
          field.longitude,
        );
        
        final maxDistance = 50.0; // 50km max reasonable distance
        final distanceScore = 1.0 - ((field.distanceKm ?? maxDistance) / maxDistance).clamp(0.0, 1.0);
        score += 0.3 * distanceScore;
      } else {
        // No location, give slight boost to popular areas
        score += 0.15; // Neutral score when no location
      }
      
      // 3. Price accessibility (20% weight) - prefer mid-range pricing
      final priceScore = 1.0 - (field.price / 200.0).clamp(0.0, 1.0); // Normalize assuming max price ~200
      score += 0.2 * priceScore;
      
      // 4. Facility completeness (10% weight) - venues with more facilities
      final facilityScore = field.facilities.length / 10.0; // Assume max 10 facilities
      score += 0.1 * facilityScore.clamp(0.0, 1.0);
      
      // Category diversity bonus - ensure variety in recommendations
      final categoryName = field.category.name;
      final currentCategoryCount = categoryCount[categoryName] ?? 0;
      if (currentCategoryCount < maxPerCategory) {
        score += 0.05; // Small bonus for category diversity
      } else {
        score -= 0.1; // Penalty for over-representation
      }
      
      scored.add(_Scored(item: field, score: score));
    }
    
    // Sort by score and apply category diversity
    scored.sort((a, b) => b.score.compareTo(a.score));
    
    final result = <SportField>[];
    final selectedCategories = <String, int>{};
    
    for (final scored_item in scored) {
      if (result.length >= topN) break;
      
      final field = scored_item.item;
      final categoryName = field.category.name;
      final categoryCount = selectedCategories[categoryName] ?? 0;
      
      // Add if we haven't exceeded category limit or if we need to fill remaining slots
      if (categoryCount < maxPerCategory || result.length < topN - 2) {
        result.add(field);
        selectedCategories[categoryName] = categoryCount + 1;
      }
    }
    
    // Track this as a generalized recommendation for learning
    if (userId != null) {
      _trackGeneralizedRecommendation(userId, result.map((f) => f.id).toList());
    }
    
    return result;
  }
  
  /// Track generalized recommendations for future learning
  static Future<void> _trackGeneralizedRecommendation(String userId, List<String> venueIds) async {
    try {
      final authBox = await Hive.openBox('auth');
      final jwtToken = authBox.get('jwt_token') as String?;
      
      if (jwtToken != null) {
        await http.post(
          Uri.parse('$apiBaseUrl/ml/track-generalized'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwtToken',
          },
          body: jsonEncode({
            'userId': userId,
            'venueIds': venueIds,
            'recommendationType': 'generalized_new_user',
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );
      }
    } catch (e) {
      print('Error tracking generalized recommendation: $e');
    }
  }
}

class _Dictionaries {
  final Map<String, int> categories;
  final Map<String, int> facilities;
  final int priceMin;
  final int priceMax;
  final int priceP75;
  final double distP95;

  _Dictionaries({
    required this.categories,
    required this.facilities,
    required this.priceMin,
    required this.priceMax,
    required this.priceP75,
    required this.distP95,
  });

  factory _Dictionaries.fromFields(List<SportField> fields) {
    final catSet = <String>{};
    final facSet = <String>{};
    final prices = <int>[];
    final dists = <double>[];

    for (final f in fields) {
      catSet.add(f.category.name);
      for (final fac in f.facilities) {
        facSet.add(fac.name);
      }
      prices.add(f.price);
      if (f.distanceKm != null) dists.add(f.distanceKm!);
    }

    final catList = catSet.toList()..sort();
    final facList = facSet.toList()..sort();

    prices.sort();
    dists.sort();

    int pInt(List<int> xs, double p) =>
        xs.isEmpty ? 0 : xs[(p * (xs.length - 1)).round()];
    double pDouble(List<double> xs, double p) =>
        xs.isEmpty ? 1.0 : xs[(p * (xs.length - 1)).round()];

    final priceMin = prices.isEmpty ? 0 : prices.first;
    final priceMax = prices.isEmpty ? 1 : prices.last;

    return _Dictionaries(
      categories: {for (var i = 0; i < catList.length; i++) catList[i]: i},
      facilities: {for (var i = 0; i < facList.length; i++) facList[i]: i},
      priceMin: priceMin,
      priceMax: priceMax,
      priceP75: pInt(prices, 0.75),
      distP95: pDouble(dists, 0.95),
    );
  }
}

class _Scored<T> {
  final T item;
  final double score;
  _Scored({required this.item, required this.score});
}
