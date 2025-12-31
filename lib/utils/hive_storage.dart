import 'package:hive_flutter/hive_flutter.dart';

/// HiveStorage for local persistence
///
/// Note: This was previously used for Supabase session storage
/// Now using Hive for all local storage including JWT tokens and notifications
class HiveStorage {
  final String key = 'jwt_auth_storage';

  Future<void> setItem(String key, String value) async {
    final box = await Hive.openBox('fitstart_auth');
    await box.put(key, value);
  }

  Future<String?> getItem(String key) async {
    final box = await Hive.openBox('fitstart_auth');
    return box.get(key) as String?;
  }

  Future<void> removeItem(String key) async {
    final box = await Hive.openBox('fitstart_auth');
    await box.delete(key);
  }
}
