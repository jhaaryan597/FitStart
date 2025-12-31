import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:FitStart/services/notification_service.dart';
import 'package:FitStart/model/notification_item.dart';

/// Test utility for notification system
class NotificationTester {
  
  /// Send a test notification to all users
  static Future<void> sendTestNotification() async {
    try {
      final success = await NotificationService.sendNotificationToAllUsers(
        title: 'Test Notification',
        body: 'This is a test notification to verify the system works!',
        data: {
          'type': 'test',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (success) {
        print('✅ Test notification sent successfully');
      } else {
        print('❌ Test notification failed to send');
      }
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }
  
  /// Add a local test notification (simulates receiving one)
  static Future<void> addLocalTestNotification() async {
    try {
      // Create a mock notification and add directly to storage
      final mockNotification = NotificationItem(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Local Test Notification',
        body: 'This is a locally generated test notification',
        timestamp: DateTime.now(),
        data: {
          'type': 'test_local',
          'timestamp': DateTime.now().toIso8601String(),
        },
        isRead: false,
        type: 'test',
      );

      // Get existing notifications
      List<NotificationItem> notifications = await NotificationService.getStoredNotifications();
      notifications.insert(0, mockNotification);

      // Save to storage
      final Box<dynamic> authBox = await Hive.openBox('fitstart_auth');
      final List<Map<String, dynamic>> jsonList = notifications.map((n) => n.toJson()).toList();
      await authBox.put('notifications', jsonEncode(jsonList));
      
      print('✅ Local test notification added');
    } catch (e) {
      print('❌ Error adding local test notification: $e');
    }
  }
  
  /// Print notification system status
  static Future<void> printNotificationStatus() async {
    try {
      final notifications = await NotificationService.getStoredNotifications();
      final unreadCount = await NotificationService.getUnreadCount();
      
      print('📊 Notification System Status:');
      print('   Total notifications: ${notifications.length}');
      print('   Unread notifications: $unreadCount');
      
      if (notifications.isNotEmpty) {
        print('   Recent notifications:');
        for (int i = 0; i < (notifications.length > 3 ? 3 : notifications.length); i++) {
          final notification = notifications[i];
          print('     - ${notification.title} (${notification.isRead ? 'Read' : 'Unread'})');
        }
      }
    } catch (e) {
      print('❌ Error getting notification status: $e');
    }
  }
}