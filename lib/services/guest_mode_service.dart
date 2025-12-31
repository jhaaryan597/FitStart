import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:FitStart/modules/auth/google_auth_view.dart';

/// Service to manage guest mode functionality
/// Guest users have limited access to certain features
class GuestModeService {
  static const String _settingsBox = 'settings';
  static const String _guestModeKey = 'guest_mode';
  static const String _userCacheBox = 'user_cache';

  /// Check if user is in guest mode
  static Future<bool> isGuestMode() async {
    try {
      final box = await Hive.openBox(_settingsBox);
      return box.get(_guestModeKey, defaultValue: false) as bool;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is in guest mode (sync version - requires box to be already open)
  static bool isGuestModeSync() {
    try {
      if (Hive.isBoxOpen(_settingsBox)) {
        final box = Hive.box(_settingsBox);
        return box.get(_guestModeKey, defaultValue: false) as bool;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if user email indicates guest
  static Future<bool> isGuestUser() async {
    try {
      final userBox = await Hive.openBox(_userCacheBox);
      final email = userBox.get('email') as String?;
      return email == null || 
             email.isEmpty || 
             email == 'guest@fitstart.local' ||
             email.contains('guest');
    } catch (e) {
      return true;
    }
  }

  /// Exit guest mode
  static Future<void> exitGuestMode() async {
    try {
      final box = await Hive.openBox(_settingsBox);
      await box.put(_guestModeKey, false);
      
      // Clear guest user data
      final userBox = await Hive.openBox(_userCacheBox);
      await userBox.delete('email');
      await userBox.delete('name');
      await userBox.delete('id');
    } catch (e) {
      // Ignore errors
    }
  }

  /// Show login required dialog for guest users
  static Future<bool> showLoginRequiredDialog(
    BuildContext context, {
    String feature = 'this feature',
  }) async {
    final isGuest = await isGuestMode();
    if (!isGuest) return true; // Not a guest, allow access

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Color(0xFF92C848)),
            SizedBox(width: 8),
            Text('Sign In Required'),
          ],
        ),
        content: Text(
          'Please sign in with Google to access $feature.\n\nGuest mode has limited functionality.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF92C848),
            ),
            child: const Text('Sign In', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await exitGuestMode();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GoogleAuthView()),
        (route) => false,
      );
    }

    return false; // Guest access denied
  }

  /// List of features restricted for guests
  static const List<String> restrictedFeatures = [
    'booking',
    'payment',
    'chat',
    'favorites',
    'become_partner',
    'reviews',
  ];

  /// Check if a feature is restricted for guests
  static bool isFeatureRestricted(String feature) {
    return restrictedFeatures.contains(feature.toLowerCase());
  }

  /// Require login for a specific action
  static Future<bool> requireLogin(
    BuildContext context, {
    required String action,
  }) async {
    final isGuest = await isGuestMode();
    if (!isGuest) return true;

    return showLoginRequiredDialog(context, feature: action);
  }
}
