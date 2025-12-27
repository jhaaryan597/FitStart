import 'package:FitStart/services/api_service.dart';

class FavoritesService {
  static Future<bool> isFavorite(String venueId) async {
    try {
      final result = await ApiService.getCurrentUser();
      if (result['success'] == true) {
        final favorites = List<String>.from(result['data']['favorites'] ?? []);
        return favorites.contains(venueId);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> toggleFavorite(String venueId) async {
    try {
      final result = await ApiService.getCurrentUser();
      if (result['success'] == true) {
        final favorites = List<String>.from(result['data']['favorites'] ?? []);
        if (favorites.contains(venueId)) {
          return await ApiService.removeFromFavorites(venueId);
        } else {
          return await ApiService.addToFavorites(venueId);
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> addFavorite(String venueId) async {
    return await ApiService.addToFavorites(venueId);
  }

  static Future<bool> removeFavorite(String venueId) async {
    return await ApiService.removeFromFavorites(venueId);
  }

  static Future<List<String>> getFavoriteVenueIds() async {
    try {
      final result = await ApiService.getCurrentUser();
      if (result['success'] == true) {
        return List<String>.from(result['data']['favorites'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
