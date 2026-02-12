// Centralized API Configuration
// Single source of truth for all API-related settings

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint, defaultTargetPlatform, TargetPlatform;

/// Centralized API configuration for the entire app.
/// All services should use this instead of defining their own URLs.
class ApiConfig {
  ApiConfig._();

  // Development URLs
  static const String _baseUrlDev = 'http://localhost:3000/api/v1';
  static const String _baseUrlAndroidEmulator = 'http://10.0.2.2:3000/api/v1';
  static const String _baseUrlAndroidDevice = 'http://10.50.84.235:3000/api/v1';

  // Production URL (Railway)
  static const String _baseUrlProd = 'https://fitstart-backend-production.up.railway.app/api/v1';

  /// API version for route prefixing
  static const String apiVersion = 'v1';

  /// Request timeout duration
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Connection timeout duration
  static const Duration connectionTimeout = Duration(seconds: 15);

  /// Whether to use production URL
  static bool get isProduction => 
      _baseUrlProd != 'https://your-railway-app.up.railway.app/api/v1';

  /// Get the appropriate base URL based on environment and platform
  static String get baseUrl {
    // Always use production URL if configured
    if (isProduction) {
      return _baseUrlProd;
    }

    // For development/testing
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Check if running on emulator or real device
      // Real devices need the host machine's IP address
      return _baseUrlAndroidDevice;
    }
    
    // iOS simulator and web use localhost
    return _baseUrlDev;
  }

  /// Get base URL for Android emulator specifically
  static String get baseUrlForEmulator => _baseUrlAndroidEmulator;

  /// Log API configuration in debug mode
  static void logConfig() {
    if (kDebugMode) {
      debugPrint('📡 API Config:');
      debugPrint('   Base URL: $baseUrl');
      debugPrint('   Is Production: $isProduction');
      debugPrint('   Platform: $defaultTargetPlatform');
    }
  }
}

/// Debug logging utility that respects kDebugMode
class AppLogger {
  AppLogger._();

  /// Log info message (only in debug mode)
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ $message');
    }
  }

  /// Log success message (only in debug mode)
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ $message');
    }
  }

  /// Log warning message (only in debug mode)
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ $message');
    }
  }

  /// Log error message (only in debug mode)
  static void error(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('❌ $message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
    }
  }

  /// Log network request (only in debug mode)
  static void network(String method, String url, {int? statusCode, String? body}) {
    if (kDebugMode) {
      debugPrint('🌐 $method $url');
      if (statusCode != null) {
        debugPrint('   Status: $statusCode');
      }
      if (body != null && body.length < 500) {
        debugPrint('   Body: $body');
      }
    }
  }
}
