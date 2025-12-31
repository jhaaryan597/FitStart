// Enhanced Cache Service with JSON serialization
// Provides type-safe caching for complex objects

import 'dart:convert';
import 'package:FitStart/core/cache/cache_manager.dart';
import 'package:FitStart/model/sport_field.dart';
import 'package:FitStart/model/gym.dart';
import 'package:FitStart/model/notification_item.dart';
import 'package:FitStart/model/sport_category.dart';
import 'package:FitStart/model/field_facility.dart';
import 'package:FitStart/model/gym_amenity.dart';

class EnhancedCacheService {
  // ==================== SPORT FIELDS ====================
  
  static Future<List<SportField>?> getSportFields() async {
    try {
      final jsonString = await CacheManager.get<String>(
        CacheKeys.sportFields,
        maxAge: CacheDuration.venues,
      );
      
      if (jsonString == null) return null;
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => _sportFieldFromJson(json)).toList();
    } catch (e) {
      print('❌ Error getting cached sport fields: $e');
      return null;
    }
  }

  static Future<void> cacheSportFields(List<SportField> fields) async {
    try {
      final jsonList = fields.map((field) => _sportFieldToJson(field)).toList();
      final jsonString = jsonEncode(jsonList);
      await CacheManager.set(CacheKeys.sportFields, jsonString);
    } catch (e) {
      print('❌ Error caching sport fields: $e');
    }
  }

  // ==================== GYMS ====================
  
  static Future<List<Gym>?> getGyms() async {
    try {
      final jsonString = await CacheManager.get<String>(
        CacheKeys.gyms,
        maxAge: CacheDuration.gyms,
      );
      
      if (jsonString == null) return null;
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => _gymFromJson(json)).toList();
    } catch (e) {
      print('❌ Error getting cached gyms: $e');
      return null;
    }
  }

  static Future<void> cacheGyms(List<Gym> gyms) async {
    try {
      final jsonList = gyms.map((gym) => _gymToJson(gym)).toList();
      final jsonString = jsonEncode(jsonList);
      await CacheManager.set(CacheKeys.gyms, jsonString);
    } catch (e) {
      print('❌ Error caching gyms: $e');
    }
  }

  // ==================== FAVORITES ====================
  
  static Future<List<String>?> getFavoriteIds() async {
    try {
      final jsonString = await CacheManager.get<String>(
        CacheKeys.favorites,
        maxAge: CacheDuration.favorites,
      );
      
      if (jsonString == null) return null;
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.cast<String>();
    } catch (e) {
      print('❌ Error getting cached favorites: $e');
      return null;
    }
  }

  static Future<void> cacheFavoriteIds(List<String> favoriteIds) async {
    try {
      final jsonString = jsonEncode(favoriteIds);
      await CacheManager.set(CacheKeys.favorites, jsonString);
    } catch (e) {
      print('❌ Error caching favorites: $e');
    }
  }

  static Future<void> invalidateFavorites() async {
    await CacheManager.delete(CacheKeys.favorites);
  }

  // ==================== NOTIFICATIONS ====================
  
  static Future<List<NotificationItem>?> getNotifications() async {
    try {
      final jsonString = await CacheManager.get<String>(
        CacheKeys.notifications,
        maxAge: CacheDuration.notifications,
      );
      
      if (jsonString == null) return null;
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => NotificationItem.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error getting cached notifications: $e');
      return null;
    }
  }

  static Future<void> cacheNotifications(List<NotificationItem> notifications) async {
    try {
      final jsonList = notifications.map((n) => n.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await CacheManager.set(CacheKeys.notifications, jsonString);
    } catch (e) {
      print('❌ Error caching notifications: $e');
    }
  }

  static Future<void> invalidateNotifications() async {
    await CacheManager.delete(CacheKeys.notifications);
    await CacheManager.delete(CacheKeys.unreadNotificationCount);
  }

  // ==================== RECOMMENDATIONS ====================
  
  static Future<List<SportField>?> getRecommendedVenues() async {
    try {
      final jsonString = await CacheManager.get<String>(
        CacheKeys.recommendedVenues,
        maxAge: CacheDuration.recommendations,
      );
      
      if (jsonString == null) return null;
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => _sportFieldFromJson(json)).toList();
    } catch (e) {
      print('❌ Error getting cached recommended venues: $e');
      return null;
    }
  }

  static Future<void> cacheRecommendedVenues(List<SportField> venues) async {
    try {
      final jsonList = venues.map((field) => _sportFieldToJson(field)).toList();
      final jsonString = jsonEncode(jsonList);
      await CacheManager.set(CacheKeys.recommendedVenues, jsonString);
    } catch (e) {
      print('❌ Error caching recommended venues: $e');
    }
  }

  static Future<List<Gym>?> getRecommendedGyms() async {
    try {
      final jsonString = await CacheManager.get<String>(
        CacheKeys.recommendedGyms,
        maxAge: CacheDuration.recommendations,
      );
      
      if (jsonString == null) return null;
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => _gymFromJson(json)).toList();
    } catch (e) {
      print('❌ Error getting cached recommended gyms: $e');
      return null;
    }
  }

  static Future<void> cacheRecommendedGyms(List<Gym> gyms) async {
    try {
      final jsonList = gyms.map((gym) => _gymToJson(gym)).toList();
      final jsonString = jsonEncode(jsonList);
      await CacheManager.set(CacheKeys.recommendedGyms, jsonString);
    } catch (e) {
      print('❌ Error caching recommended gyms: $e');
    }
  }

  // ==================== SEARCH RESULTS ====================
  
  static Future<List<SportField>?> getSearchResults(String query) async {
    try {
      final jsonString = await CacheManager.get<String>(
        CacheKeys.searchResults(query),
        maxAge: CacheDuration.searchResults,
      );
      
      if (jsonString == null) return null;
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => _sportFieldFromJson(json)).toList();
    } catch (e) {
      print('❌ Error getting cached search results: $e');
      return null;
    }
  }

  static Future<void> cacheSearchResults(String query, List<SportField> results) async {
    try {
      final jsonList = results.map((field) => _sportFieldToJson(field)).toList();
      final jsonString = jsonEncode(jsonList);
      await CacheManager.set(CacheKeys.searchResults(query), jsonString);
    } catch (e) {
      print('❌ Error caching search results: $e');
    }
  }

  // ==================== CACHE MAINTENANCE ====================
  
  static Future<void> invalidateAll() async {
    await CacheManager.clearAll();
  }

  static Future<void> invalidateVenues() async {
    await CacheManager.delete(CacheKeys.sportFields);
    await CacheManager.delete(CacheKeys.recommendedVenues);
  }

  static Future<void> invalidateGyms() async {
    await CacheManager.delete(CacheKeys.gyms);
    await CacheManager.delete(CacheKeys.recommendedGyms);
  }

  // ==================== SERIALIZATION HELPERS ====================
  
  static Map<String, dynamic> _sportFieldToJson(SportField field) {
    return {
      'id': field.id,
      'name': field.name,
      'category': {
        'name': field.category.name,
        'image': field.category.image,
      },
      'facilities': field.facilities.map((f) => {
        'name': f.name,
        'imageAsset': f.imageAsset,
      }).toList(),
      'address': field.address,
      'phoneNumber': field.phoneNumber,
      'email': field.email,
      'openDay': field.openDay,
      'openTime': field.openTime,
      'closeTime': field.closeTime,
      'imageAsset': field.imageAsset,
      'price': field.price,
      'latitude': field.latitude,
      'longitude': field.longitude,
      'rating': field.rating,
      'distanceKm': field.distanceKm,
      'author': field.author,
      'authorUrl': field.authorUrl,
      'imageUrl': field.imageUrl,
    };
  }

  static SportField _sportFieldFromJson(Map<String, dynamic> json) {
    return SportField(
      id: json['id'],
      name: json['name'],
      category: SportCategory(
        name: json['category']['name'],
        image: json['category']['image'],
      ),
      facilities: (json['facilities'] as List).map((f) => FieldFacility(
        name: f['name'],
        imageAsset: f['imageAsset'],
      )).toList(),
      address: json['address'],
      phoneNumber: json['phoneNumber'],
      email: json['email'] ?? 'abhjha597@gmail.com',
      openDay: json['openDay'],
      openTime: json['openTime'],
      closeTime: json['closeTime'],
      imageAsset: json['imageAsset'],
      price: json['price'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      rating: json['rating'],
      author: json['author'],
      authorUrl: json['authorUrl'],
      imageUrl: json['imageUrl'],
    )..distanceKm = json['distanceKm'];
  }

  static Map<String, dynamic> _gymToJson(Gym gym) {
    return {
      'id': gym.id,
      'name': gym.name,
      'type': gym.type,
      'amenities': gym.amenities.map((a) => {
        'name': a.name,
        'imageAsset': a.imageAsset,
      }).toList(),
      'address': gym.address,
      'phoneNumber': gym.phoneNumber,
      'email': gym.email,
      'openDay': gym.openDay,
      'openTime': gym.openTime,
      'closeTime': gym.closeTime,
      'imageAsset': gym.imageAsset,
      'monthlyPrice': gym.monthlyPrice,
      'dailyPrice': gym.dailyPrice,
      'latitude': gym.latitude,
      'longitude': gym.longitude,
      'rating': gym.rating,
      'distanceKm': gym.distanceKm,
      'author': gym.author,
      'authorUrl': gym.authorUrl,
      'imageUrl': gym.imageUrl,
      'hasPersonalTrainer': gym.hasPersonalTrainer,
      'hasGroupClasses': gym.hasGroupClasses,
      'trainerPrice': gym.trainerPrice,
      'description': gym.description,
    };
  }

  static Gym _gymFromJson(Map<String, dynamic> json) {
    return Gym(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      amenities: (json['amenities'] as List).map((a) => GymAmenity(
        name: a['name'],
        imageAsset: a['imageAsset'],
      )).toList(),
      address: json['address'],
      phoneNumber: json['phoneNumber'],
      email: json['email'] ?? 'abhjha597@gmail.com',
      openDay: json['openDay'],
      openTime: json['openTime'],
      closeTime: json['closeTime'],
      imageAsset: json['imageAsset'],
      monthlyPrice: json['monthlyPrice'],
      dailyPrice: json['dailyPrice'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      rating: json['rating'],
      author: json['author'],
      authorUrl: json['authorUrl'],
      imageUrl: json['imageUrl'],
      hasPersonalTrainer: json['hasPersonalTrainer'] ?? false,
      hasGroupClasses: json['hasGroupClasses'] ?? false,
      trainerPrice: json['trainerPrice'] ?? 0,
      description: json['description'],
    )..distanceKm = json['distanceKm'];
  }
}
