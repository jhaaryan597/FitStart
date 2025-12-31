import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static Box? _box;

  // Cache keys
  static const String _keyUsername = 'cached_username';
  static const String _keyProfileImage = 'cached_profile_image';
  static const String _keySavedLocation = 'cached_saved_location';
  static const String _keyRecommendations = 'cached_recommendations';
  static const String _keyRecommendationsTimestamp =
      'cached_recommendations_timestamp';
  static const String _keyUserDataTimestamp = 'cached_user_data_timestamp';

  // Cache duration (in minutes)
  static const int _userDataCacheDuration = 60; // 1 hour
  static const int _recommendationsCacheDuration = 30; // 30 minutes

  Future<void> init() async {
    _box ??= await Hive.openBox('app_cache');
  }

  // User data caching
  Future<void> cacheUserData({
    required String username,
    String? profileImage,
  }) async {
    await init();
    await _box!.put(_keyUsername, username);
    if (profileImage != null) {
      await _box!.put(_keyProfileImage, profileImage);
    }
    await _box!.put(_keyUserDataTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  Map<String, String?>? getCachedUserData() {
    if (_box == null) return null;

    final timestamp = _box!.get(_keyUserDataTimestamp) as int?;
    if (timestamp == null) return null;

    // Check if cache is expired
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (now.difference(cacheTime).inMinutes > _userDataCacheDuration) {
      return null; // Cache expired
    }

    final username = _box!.get(_keyUsername) as String?;
    final profileImage = _box!.get(_keyProfileImage) as String?;

    if (username == null) return null;

    return {
      'username': username,
      'profile_image': profileImage,
    };
  }

  // Location caching
  Future<void> cacheSavedLocation(String location) async {
    await init();
    await _box!.put(_keySavedLocation, location);
  }

  String? getCachedLocation() {
    return _box?.get(_keySavedLocation) as String?;
  }

  // ML Recommendations caching
  Future<void> cacheRecommendations(
      List<Map<String, dynamic>> recommendations) async {
    await init();
    final jsonString = jsonEncode(recommendations);
    await _box!.put(_keyRecommendations, jsonString);
    await _box!.put(_keyRecommendationsTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  List<Map<String, dynamic>>? getCachedRecommendations() {
    if (_box == null) return null;

    final timestamp = _box!.get(_keyRecommendationsTimestamp) as int?;
    if (timestamp == null) return null;

    // Check if cache is expired
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (now.difference(cacheTime).inMinutes > _recommendationsCacheDuration) {
      return null; // Cache expired
    }

    final jsonString = _box!.get(_keyRecommendations) as String?;
    if (jsonString == null) return null;

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  // Clear specific cache
  Future<void> clearUserDataCache() async {
    await init();
    await _box!.delete(_keyUsername);
    await _box!.delete(_keyProfileImage);
    await _box!.delete(_keyUserDataTimestamp);
  }

  Future<void> clearRecommendationsCache() async {
    await init();
    await _box!.delete(_keyRecommendations);
    await _box!.delete(_keyRecommendationsTimestamp);
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    await init();
    await _box!.clear();
  }
}
