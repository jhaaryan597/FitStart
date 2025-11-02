import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:FitStart/model/notification_item.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:FitStart/modules/notification/notification_view.dart';
import 'package:FitStart/main.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print("Background Message: ${message.messageId}");
    print("Title: ${message.notification?.title}");
    print("Body: ${message.notification?.body}");
    print("Data: ${message.data}");
  }

  // Store notification even in background
  await NotificationService._saveNotificationToStorage(message);
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  String? _fcmToken;
  static const String _notificationsKey = 'stored_notifications';

  String? get fcmToken => _fcmToken;

  // Get stored notifications
  static Future<List<NotificationItem>> getStoredNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notificationsJson = prefs.getString(_notificationsKey);

      if (notificationsJson == null) return [];

      final List<dynamic> decoded = jsonDecode(notificationsJson);
      return decoded.map((json) => NotificationItem.fromJson(json)).toList()
        ..sort((a, b) =>
            b.timestamp.compareTo(a.timestamp)); // Sort by newest first
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notifications: $e');
      }
      return [];
    }
  }

  // Save notification to local storage
  static Future<void> _saveNotificationToStorage(RemoteMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing notifications
      List<NotificationItem> notifications = await getStoredNotifications();

      // Create new notification item
      final newNotification = NotificationItem(
        id: message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? '',
        timestamp: DateTime.now(),
        data: message.data,
        isRead: false,
        imageUrl: message.notification?.android?.imageUrl ??
            message.notification?.apple?.imageUrl,
        type: message.data['type'] ?? 'system',
      );

      // Add to beginning of list
      notifications.insert(0, newNotification);

      // Keep only last 100 notifications
      if (notifications.length > 100) {
        notifications = notifications.sublist(0, 100);
      }

      // Save back to storage
      final List<Map<String, dynamic>> jsonList =
          notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(jsonList));

      if (kDebugMode) {
        print('✅ Notification saved to storage: ${newNotification.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving notification: $e');
      }
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      List<NotificationItem> notifications = await getStoredNotifications();

      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);

        final prefs = await SharedPreferences.getInstance();
        final List<Map<String, dynamic>> jsonList =
            notifications.map((n) => n.toJson()).toList();
        await prefs.setString(_notificationsKey, jsonEncode(jsonList));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      List<NotificationItem> notifications = await getStoredNotifications();

      notifications =
          notifications.map((n) => n.copyWith(isRead: true)).toList();

      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList =
          notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(jsonList));
    } catch (e) {
      if (kDebugMode) {
        print('Error marking all as read: $e');
      }
    }
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      List<NotificationItem> notifications = await getStoredNotifications();

      notifications.removeWhere((n) => n.id == notificationId);

      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList =
          notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(jsonList));
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification: $e');
      }
    }
  }

  // Clear all notifications
  static Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing notifications: $e');
      }
    }
  }

  // Get unread count
  static Future<int> getUnreadCount() async {
    final notifications = await getStoredNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  /// Initialize Firebase Messaging and request permissions
  Future<void> init() async {
    // Initialize local notifications
    await _initializeLocalNotifications();

    // Request notification permissions (especially for iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('Notification permission granted: ${settings.authorizationStatus}');
    }

    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    if (kDebugMode) {
      print('═══════════════════════════════════════');
      print('FCM Token: $_fcmToken');
      print('═══════════════════════════════════════');
    }

    // Save FCM token to Supabase profile (optional - for sending targeted notifications)
    await _saveFCMTokenToProfile();

    // Subscribe to topics
    await _firebaseMessaging.subscribeToTopic("all");
    if (kDebugMode) {
      print('Subscribed to topic: all');
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      if (kDebugMode) {
        print('FCM Token refreshed: $newToken');
      }
      _saveFCMTokenToProfile();
    });

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (kDebugMode) {
        print('📱 Foreground Message Received!');
        print('Message ID: ${message.messageId}');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
        print('Data: ${message.data}');
        print('From: ${message.from}');
      }

      // Save notification to storage
      await _saveNotificationToStorage(message);
      if (kDebugMode) {
        print('✅ Notification saved to storage');
      }

      // Show local notification when app is in foreground
      await _showLocalNotification(message);
      if (kDebugMode) {
        print('✅ Local notification displayed');
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('🔔 Notification tapped (app in background)');
        print('Message data: ${message.data}');
      }
      // Navigate to specific screen based on message data
      _handleNotificationTap(message);
    });

    // Check if app was opened from a terminated state via notification
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        print('🚀 App opened from terminated state via notification');
      }
      _handleNotificationTap(initialMessage);
    }
  }

  /// Save FCM token to user's Supabase profile
  Future<void> _saveFCMTokenToProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && _fcmToken != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': _fcmToken}).eq('id', user.id);

        if (kDebugMode) {
          print('✅ FCM token saved to profile');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving FCM token: $e');
      }
    }
  }

  /// Handle notification tap - navigate to appropriate screen
  void _handleNotificationTap(RemoteMessage message) async {
    if (kDebugMode) {
      print('🔔 Notification tapped, navigating to notification screen');
      print('Message: ${message.notification?.title}');
    }

    // Save notification to storage first (in case it wasn't saved yet)
    await _saveNotificationToStorage(message);
    if (kDebugMode) {
      print('✅ Notification saved before navigation');
    }

    // Navigate to notification screen when notification is tapped
    // Use Future.delayed to ensure navigation happens after app is fully initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => const NotificationView(),
        ),
      );
    });
  }

  /// Subscribe to a specific topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    if (kDebugMode) {
      print('✅ Subscribed to topic: $topic');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    if (kDebugMode) {
      print('❌ Unsubscribed from topic: $topic');
    }
  }

  /// Delete FCM token (useful for logout)
  Future<void> deleteFCMToken() async {
    await _firebaseMessaging.deleteToken();
    _fcmToken = null;
    if (kDebugMode) {
      print('🗑️ FCM token deleted');
    }
  }

  /// Send notification to all users via Supabase Edge Function
  static Future<bool> sendNotificationToAllUsers({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'send-campaign-notification',
        body: {
          'title': title,
          'body': body,
          'data': data ?? {},
          'target_type': 'all',
        },
      );

      if (kDebugMode) {
        print('✅ Notification sent to all users');
        print('Response: ${response.data}');
      }

      return response.data['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending notification: $e');
      }
      return false;
    }
  }

  /// Send notification to specific users via Supabase Edge Function
  static Future<bool> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'send-campaign-notification',
        body: {
          'title': title,
          'body': body,
          'data': data ?? {},
          'target_type': 'specific',
          'user_ids': userIds,
        },
      );

      if (kDebugMode) {
        print('✅ Notification sent to ${userIds.length} users');
        print('Response: ${response.data}');
      }

      return response.data['success'] == true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending notification: $e');
      }
      return false;
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (kDebugMode) {
          print(
              '🔔 Local notification tapped, navigating to notification screen');
        }
        // Navigate to notification screen when local notification is tapped
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => const NotificationView(),
          ),
        );
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    if (kDebugMode) {
      print('✅ Local notifications initialized');
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.notification.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      platformDetails,
      payload: message.data.toString(),
    );

    if (kDebugMode) {
      print('✅ Local notification shown');
    }
  }
}
