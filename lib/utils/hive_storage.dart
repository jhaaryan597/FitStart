import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HiveStorage extends LocalStorage {
  HiveStorage() : super();

  @override
  Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox('supabase_authentication');
  }

  @override
  Future<bool> hasAccessToken() async {
    return Hive.box('supabase_authentication')
        .containsKey(supabasePersistSessionKey);
  }

  @override
  Future<String?> accessToken() async {
    return Hive.box('supabase_authentication').get(supabasePersistSessionKey);
  }

  @override
  Future<void> removePersistedSession() async {
    await Hive.box('supabase_authentication').delete(supabasePersistSessionKey);
  }

  @override
  Future<void> persistSession(String session) async {
    await Hive.box('supabase_authentication')
        .put(supabasePersistSessionKey, session);
  }
}
