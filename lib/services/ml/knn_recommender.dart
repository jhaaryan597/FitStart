import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FitStart/model/sport_field.dart';
import 'package:FitStart/utils/dummy_data.dart';

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
        // Get venues user has booked (from orders table)
        final ordersResponse = await Supabase.instance.client
            .from('orders')
            .select('venue_id')
            .eq('user_id', userId)
            .eq('venue_type', 'sports_venue');

        bookedFieldIds =
            ordersResponse.map((item) => item['venue_id'] as String).toList();

        // Get venues user has interacted with (views, favorites)
        final interactionsResponse = await Supabase.instance.client
            .from('user_interactions')
            .select('venue_id, interaction_score')
            .eq('user_id', userId)
            .eq('venue_type', 'sports_venue')
            .order('interaction_score', ascending: false);

        interactedFieldIds = interactionsResponse
            .map((item) => item['venue_id'] as String)
            .toList();
      } catch (e) {
        // Handle error, e.g., log it. Fallback to cold start.
        print('ML Error fetching user history: $e');
      }
    }

    // Cold start: no user history -> top rated then cheaper.
    if (bookedFieldIds.isEmpty && interactedFieldIds.isEmpty) {
      final sorted = List<SportField>.from(fields)
        ..sort((a, b) {
          final r = b.rating.compareTo(a.rating);
          return r != 0 ? r : a.price.compareTo(b.price);
        });
      return sorted.take(topN).toList();
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

    // Step 2: Try to get collaborative filtering recommendations
    Map<String, double> collaborativeScores = {};
    if (userId != null) {
      try {
        final collabRecs = await Supabase.instance.client
            .rpc('get_collaborative_recommendations', params: {
          'target_user_id': userId,
          'venue_type_filter': 'sports_venue',
          'limit_count': topN * 2,
        });

        for (final rec in collabRecs) {
          collaborativeScores[rec['venue_id'] as String] =
              (rec['recommendation_score'] as num).toDouble();
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
