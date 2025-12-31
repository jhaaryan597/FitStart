// Comprehensive Cache Manager using Hive
// Handles all caching logic with TTL (Time-To-Live) and cache invalidation

import 'package:hive_flutter/hive_flutter.dart';

class CacheManager {
  static const String _cacheBoxName = 'app_cache';
  static const String _metaBoxName = 'cache_metadata';
  
  static Box? _cacheBox;
  static Box? _metaBox;

  /// Initialize cache manager
  static Future<void> init() async {
    _cacheBox = await Hive.openBox(_cacheBoxName);
    _metaBox = await Hive.openBox(_metaBoxName);
  }

  /// Get cached data with TTL check
  static Future<T?> get<T>(
    String key, {
    Duration? maxAge,
  }) async {
    try {
      final box = _cacheBox ?? await Hive.openBox(_cacheBoxName);
      final metaBox = _metaBox ?? await Hive.openBox(_metaBoxName);

      // Check if key exists
      if (!box.containsKey(key)) {
        return null;
      }

      // Check TTL if maxAge is specified
      if (maxAge != null) {
        final timestamp = metaBox.get('${key}_timestamp') as int?;
        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final age = DateTime.now().difference(cacheTime);
          
          if (age > maxAge) {
            // Cache expired, remove it
            await delete(key);
            return null;
          }
        }
      }

      final data = box.get(key);
      if (data is Map && T == Map<String, dynamic>) {
        return Map<String, dynamic>.from(data) as T?;
      }
      return data as T?;
    } catch (e) {
      print('❌ Cache get error for key $key: $e');
      return null;
    }
  }

  /// Store data in cache with timestamp
  static Future<void> set<T>(String key, T value) async {
    try {
      final box = _cacheBox ?? await Hive.openBox(_cacheBoxName);
      final metaBox = _metaBox ?? await Hive.openBox(_metaBoxName);

      await box.put(key, value);
      await metaBox.put('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('❌ Cache set error for key $key: $e');
    }
  }

  /// Delete specific cache entry
  static Future<void> delete(String key) async {
    try {
      final box = _cacheBox ?? await Hive.openBox(_cacheBoxName);
      final metaBox = _metaBox ?? await Hive.openBox(_metaBoxName);

      await box.delete(key);
      await metaBox.delete('${key}_timestamp');
    } catch (e) {
      print('❌ Cache delete error for key $key: $e');
    }
  }

  /// Delete all cache entries matching a prefix
  static Future<void> deleteByPrefix(String prefix) async {
    try {
      final box = _cacheBox ?? await Hive.openBox(_cacheBoxName);
      final metaBox = _metaBox ?? await Hive.openBox(_metaBoxName);

      final keysToDelete = box.keys.where((key) => key.toString().startsWith(prefix)).toList();
      
      for (var key in keysToDelete) {
        await box.delete(key);
        await metaBox.delete('${key}_timestamp');
      }
    } catch (e) {
      print('❌ Cache deleteByPrefix error: $e');
    }
  }

  /// Clear all cache
  static Future<void> clearAll() async {
    try {
      final box = _cacheBox ?? await Hive.openBox(_cacheBoxName);
      final metaBox = _metaBox ?? await Hive.openBox(_metaBoxName);

      await box.clear();
      await metaBox.clear();
    } catch (e) {
      print('❌ Cache clearAll error: $e');
    }
  }

  /// Check if cache exists and is valid
  static Future<bool> has(String key, {Duration? maxAge}) async {
    final value = await get(key, maxAge: maxAge);
    return value != null;
  }

  /// Get cache age
  static Future<Duration?> getAge(String key) async {
    try {
      final metaBox = _metaBox ?? await Hive.openBox(_metaBoxName);
      final timestamp = metaBox.get('${key}_timestamp') as int?;
      
      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return DateTime.now().difference(cacheTime);
      }
    } catch (e) {
      print('❌ Cache getAge error: $e');
    }
    return null;
  }

  /// Get cache size
  static Future<int> getCacheSize() async {
    try {
      final box = _cacheBox ?? await Hive.openBox(_cacheBoxName);
      return box.length;
    } catch (e) {
      return 0;
    }
  }

  /// Clean expired entries
  static Future<void> cleanExpired(Duration maxAge) async {
    try {
      final box = _cacheBox ?? await Hive.openBox(_cacheBoxName);
      final metaBox = _metaBox ?? await Hive.openBox(_metaBoxName);

      final keysToDelete = <String>[];
      
      for (var key in box.keys) {
        final timestamp = metaBox.get('${key}_timestamp') as int?;
        if (timestamp != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final age = DateTime.now().difference(cacheTime);
          
          if (age > maxAge) {
            keysToDelete.add(key.toString());
          }
        }
      }

      for (var key in keysToDelete) {
        await box.delete(key);
        await metaBox.delete('${key}_timestamp');
      }

      print('✅ Cleaned ${keysToDelete.length} expired cache entries');
    } catch (e) {
      print('❌ Cache cleanExpired error: $e');
    }
  }
}

/// Cache keys constants for consistency
class CacheKeys {
  // Venues
  static const String sportFields = 'sport_fields';
  static const String sportFieldsPrefix = 'sport_field_';
  
  // Gyms
  static const String gyms = 'gyms';
  static const String gymsPrefix = 'gym_';
  
  // Favorites
  static const String favorites = 'favorites';
  
  // Notifications
  static const String notifications = 'notifications';
  static const String unreadNotificationCount = 'unread_notification_count';
  
  // User
  static const String userProfile = 'user_profile';
  
  // Transactions
  static const String transactions = 'transactions';
  static const String orders = 'orders';
  
  // ML Recommendations
  static const String recommendedVenues = 'recommended_venues';
  static const String recommendedGyms = 'recommended_gyms';
  
  // Search
  static String searchResults(String query) => 'search_results_$query';
  
  // Categories
  static const String categories = 'categories';
}

/// Cache durations for different types of data
class CacheDuration {
  static const Duration short = Duration(minutes: 5);
  static const Duration medium = Duration(minutes: 15);
  static const Duration long = Duration(hours: 1);
  static const Duration veryLong = Duration(hours: 24);
  
  // Specific durations
  static const Duration venues = Duration(minutes: 30);
  static const Duration gyms = Duration(minutes: 30);
  static const Duration favorites = Duration(minutes: 10);
  static const Duration notifications = Duration(minutes: 5);
  static const Duration recommendations = Duration(hours: 6);
  static const Duration searchResults = Duration(minutes: 15);
  static const Duration userProfile = Duration(minutes: 30);
}
