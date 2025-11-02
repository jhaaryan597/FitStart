import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesService {
  static final _supabase = Supabase.instance.client;

  /// Add a venue to favorites
  static Future<bool> addFavorite(String venueId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase.from('favorites').insert({
        'user_id': userId,
        'venue_id': venueId,
      });

      return true;
    } catch (e) {
      print('Error adding favorite: $e');
      return false;
    }
  }

  /// Remove a venue from favorites
  static Future<bool> removeFavorite(String venueId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('venue_id', venueId);

      return true;
    } catch (e) {
      print('Error removing favorite: $e');
      return false;
    }
  }

  /// Check if a venue is favorited by the current user
  static Future<bool> isFavorite(String venueId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return false;
      }

      final response = await _supabase
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('venue_id', venueId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  /// Get all favorite venue IDs for the current user
  static Future<List<String>> getFavoriteVenueIds() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return [];
      }

      final response = await _supabase
          .from('favorites')
          .select('venue_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => e['venue_id'] as String).toList();
    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }

  /// Toggle favorite status for a venue
  static Future<bool> toggleFavorite(String venueId) async {
    final isFav = await isFavorite(venueId);
    if (isFav) {
      return await removeFavorite(venueId);
    } else {
      return await addFavorite(venueId);
    }
  }
}
