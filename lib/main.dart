import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:FitStart/modules/splash/splash_view.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/injection_container.dart' as di;
import 'package:FitStart/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:FitStart/features/auth/presentation/bloc/auth_event.dart';
import 'package:FitStart/core/cache/cache_manager.dart';
import 'package:FitStart/services/favorites_service.dart';
import 'package:FitStart/utils/location_service.dart';
import 'package:FitStart/services/notification_service.dart';

// Global navigation key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('⚠️ Firebase initialization error: $e');
  }
  
  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('fitstart_auth');
  
  // Initialize Cache Manager
  await CacheManager.init();
  
  // Initialize Favorites Service
  await FavoritesService.init();
  
  // Initialize Location Service (load cached location)
  await LocationService.init();
  
  // Clean expired cache entries on startup (older than 7 days)
  await CacheManager.cleanExpired(const Duration(days: 7));
  
  // Initialize date formatting
  await initializeDateFormatting('en', null);
  
  // Initialize dependency injection
  await di.init();
  
  // Initialize notifications
  try {
    final notificationService = NotificationService();
    await notificationService.init();
    print('✅ Notifications initialized successfully');
  } catch (e) {
    print('⚠️ Notification initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Auth BLoC
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>()..add(CheckAuthStatusEvent()),
        ),
        // Add more BLoCs here as you migrate features
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'FitStart',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light, // Will add theme manager with BLoC later
        locale: const Locale('en', 'EN'),
        home: const SplashView(),
      ),
    );
  }
}
