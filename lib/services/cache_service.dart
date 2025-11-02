import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static SharedPreferences? _prefs;

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
    _prefs ??= await SharedPreferences.getInstance();
  }

  // User data caching
  Future<void> cacheUserData({
    required String username,
    String? profileImage,
  }) async {
    await init();
    await _prefs!.setString(_keyUsername, username);
    if (profileImage != null) {
      await _prefs!.setString(_keyProfileImage, profileImage);
    }
    await _prefs!
        .setInt(_keyUserDataTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  Map<String, String?>? getCachedUserData() {
    if (_prefs == null) return null;

    final timestamp = _prefs!.getInt(_keyUserDataTimestamp);
    if (timestamp == null) return null;

    // Check if cache is expired
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (now.difference(cacheTime).inMinutes > _userDataCacheDuration) {
      return null; // Cache expired
    }

    final username = _prefs!.getString(_keyUsername);
    final profileImage = _prefs!.getString(_keyProfileImage);

    if (username == null) return null;

    return {
      'username': username,
      'profile_image': profileImage,
    };
  }

  // Location caching
  Future<void> cacheSavedLocation(String location) async {
    await init();
    await _prefs!.setString(_keySavedLocation, location);
  }

  String? getCachedLocation() {
    return _prefs?.getString(_keySavedLocation);
  }

  // ML Recommendations caching
  Future<void> cacheRecommendations(
      List<Map<String, dynamic>> recommendations) async {
    await init();
    final jsonString = jsonEncode(recommendations);
    await _prefs!.setString(_keyRecommendations, jsonString);
    await _prefs!.setInt(
        _keyRecommendationsTimestamp, DateTime.now().millisecondsSinceEpoch);
  }

  List<Map<String, dynamic>>? getCachedRecommendations() {
    if (_prefs == null) return null;

    final timestamp = _prefs!.getInt(_keyRecommendationsTimestamp);
    if (timestamp == null) return null;

    // Check if cache is expired
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (now.difference(cacheTime).inMinutes > _recommendationsCacheDuration) {
      return null; // Cache expired
    }

    final jsonString = _prefs!.getString(_keyRecommendations);
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
    await _prefs!.remove(_keyUsername);
    await _prefs!.remove(_keyProfileImage);
    await _prefs!.remove(_keyUserDataTimestamp);
  }

  Future<void> clearRecommendationsCache() async {
    await init();
    await _prefs!.remove(_keyRecommendations);
    await _prefs!.remove(_keyRecommendationsTimestamp);
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    await init();
    await _prefs!.clear();
  }
}
