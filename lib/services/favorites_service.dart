import 'package:FitStart/services/api_service.dart';
import 'package:FitStart/services/enhanced_cache_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class FavoritesService {
  // Cache for quick access
  static List<String>? _cachedFavoriteIds;
  static const String _localFavoritesKey = 'local_favorites';
  
  /// Initialize favorites from local storage
  static Future<void> init() async {
    try {
      // Try enhanced cache first
      final cachedIds = await EnhancedCacheService.getFavoriteIds();
      if (cachedIds != null && cachedIds.isNotEmpty) {
        _cachedFavoriteIds = cachedIds;
        return;
      }
      
      // Fall back to Hive for backwards compatibility
      final box = await Hive.openBox('favorites');
      final localFavorites = box.get(_localFavoritesKey, defaultValue: <String>[]) as List;
      _cachedFavoriteIds = List<String>.from(localFavorites);
      
      // Cache to enhanced cache
      if (_cachedFavoriteIds!.isNotEmpty) {
        await EnhancedCacheService.cacheFavoriteIds(_cachedFavoriteIds!);
      }
    } catch (e) {
      print('❌ Error initializing favorites: $e');
      _cachedFavoriteIds = [];
    }
  }
  
  static Future<bool> isFavorite(String venueId) async {
    try {
      // Initialize if not already done
      if (_cachedFavoriteIds == null) {
        await init();
      }
      
      return _cachedFavoriteIds?.contains(venueId) ?? false;
    } catch (e) {
      print('❌ Error checking favorite: $e');
      return false;
    }
  }

  static Future<bool> toggleFavorite(String venueId) async {
    try {
      // Initialize if not already done
      if (_cachedFavoriteIds == null) {
        await init();
      }
      
      final bool isFav = _cachedFavoriteIds?.contains(venueId) ?? false;
      
      // Optimistic update - update cache immediately for instant UI feedback
      if (isFav) {
        _cachedFavoriteIds?.remove(venueId);
      } else {
        _cachedFavoriteIds ??= [];
        _cachedFavoriteIds!.add(venueId);
      }
      await _saveToLocalStorage();
      
      // Try to sync with server in background
      try {
        if (isFav) {
          await ApiService.removeFromFavorites(venueId);
        } else {
          await ApiService.addToFavorites(venueId);
        }
      } catch (e) {
        print('⚠️  API call failed, using local storage: $e');
        // API failed but local storage updated - this is okay for offline support
      }
      
      return true; // Always return true since local storage works
    } catch (e) {
      print('❌ Error toggling favorite: $e');
      return false;
    }
  }

  static Future<bool> addFavorite(String venueId) async {
    try {
      if (_cachedFavoriteIds == null) {
        await init();
      }
      
      if (_cachedFavoriteIds!.contains(venueId)) {
        return true; // Already favorited
      }
      
      // Optimistic update
      _cachedFavoriteIds!.add(venueId);
      await _saveToLocalStorage();
      
      // Try API
      try {
        await ApiService.addToFavorites(venueId);
      } catch (e) {
        print('⚠️  API call failed: $e');
      }
      
      return true;
    } catch (e) {
      print('❌ Error adding favorite: $e');
      return false;
    }
  }

  static Future<bool> removeFavorite(String venueId) async {
    try {
      if (_cachedFavoriteIds == null) {
        await init();
      }
      
      // Optimistic update
      _cachedFavoriteIds?.remove(venueId);
      await _saveToLocalStorage();
      
      // Try API
      try {
        await ApiService.removeFromFavorites(venueId);
      } catch (e) {
        print('⚠️  API call failed: $e');
      }
      
      return true;
    } catch (e) {
      print('❌ Error removing favorite: $e');
      return false;
    }
  }

  static Future<List<String>> getFavoriteVenueIds() async {
    try {
      if (_cachedFavoriteIds == null) {
        await init();
      }
      
      return List<String>.from(_cachedFavoriteIds ?? []);
    } catch (e) {
      print('❌ Error getting favorites: $e');
      return [];
    }
  }
  
  /// Save to both Hive and enhanced cache
  static Future<void> _saveToLocalStorage() async {
    try {
      if (_cachedFavoriteIds != null) {
        // Save to Hive
        final box = await Hive.openBox('favorites');
        await box.put(_localFavoritesKey, _cachedFavoriteIds!);
        
        // Save to enhanced cache
        await EnhancedCacheService.cacheFavoriteIds(_cachedFavoriteIds!);
      }
    } catch (e) {
      print('❌ Error saving favorites: $e');
    }
  }
  
  /// Sync with server (call when back online)
  static Future<void> syncWithServer() async {
    try {
      // Try to get favorites from server
      final result = await ApiService.getCurrentUser();
      if (result['success'] == true && result['data'] != null) {
        final serverFavorites = List<String>.from(result['data']['favorites'] ?? []);
        
        // Merge with local favorites (local takes precedence)
        final localFavorites = _cachedFavoriteIds ?? [];
        final merged = {...serverFavorites, ...localFavorites}.toList();
        
        _cachedFavoriteIds = merged;
        await _saveToLocalStorage();
        
        print('✅ Synced favorites with server');
      }
    } catch (e) {
      print('❌ Error syncing with server: $e');
    }
  }
  
  /// Clear favorites cache (call on logout)
  static Future<void> clearCache() async {
    _cachedFavoriteIds = null;
    await EnhancedCacheService.invalidateFavorites();
    
    final box = await Hive.openBox('favorites');
    await box.delete(_localFavoritesKey);
  }
  
  /// Refresh favorites from server
  static Future<void> refresh() async {
    _cachedFavoriteIds = null;
    await EnhancedCacheService.invalidateFavorites();
    await init();
  }
}

