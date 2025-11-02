import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:FitStart/modules/splash/splash_view.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/utils/hive_storage.dart';
import 'package:FitStart/utils/theme_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FitStart/services/notification_service.dart';

// Global navigation key for notification navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await Hive.openBox('supabase_authentication');
  await Supabase.initialize(
    url: 'https://YOUR_PROJECT.supabase.co',
    anonKey:
        'REDACTED_SUPABASE_ANON_KEY',
    authOptions: FlutterAuthClientOptions(
      localStorage: HiveStorage(),
    ),
  );
  await initializeDateFormatting('en', null);

  final NotificationService notificationService = NotificationService();
  await notificationService.init();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeManager = ref.watch(themeManagerProvider);
    return MaterialApp(
      navigatorKey:
          navigatorKey, // Add navigation key for notification navigation
      title: 'FitStart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeManager.themeMode,
      locale: const Locale('en', 'EN'),
      home: const SplashView(),
    );
  }
}
