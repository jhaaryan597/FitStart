import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

/// Service for handling internal chat functionality between users and venue owners
class ChatService {
  static const String _baseUrl = 'https://fitstart-backend-production.up.railway.app/api/v1';

  /// Get headers with authentication token
  static Future<Map<String, String>> _getHeaders() async {
    final authBox = await Hive.openBox('auth');
    final token = authBox.get('jwt_token') as String?;
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Start a conversation with venue owner
  static Future<Map<String, dynamic>> startConversation({
    required String venueId,
    required String venueType, // 'gym' or 'sports_venue'
    required String venueName,
    required String initialMessage,
  }) async {
    try {
      if (kDebugMode) {
        print('📤 Starting conversation with venue: $venueId');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/conversations'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'venueId': venueId,
          'venueType': venueType,
          'venueName': venueName,
          'initialMessage': initialMessage,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ Conversation started successfully');
        }
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to start conversation'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting conversation: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Send a message in existing conversation
  static Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String message,
  }) async {
    try {
      if (kDebugMode) {
        print('📤 Sending message to conversation: $conversationId');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/conversations/$conversationId/messages'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'message': message,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to send message'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending message: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get conversation history
  static Future<Map<String, dynamic>> getConversation(String conversationId) async {
    try {
      if (kDebugMode) {
        print('📤 Getting conversation: $conversationId');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/conversations/$conversationId'),
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to get conversation'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting conversation: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get all user's conversations
  static Future<Map<String, dynamic>> getUserConversations() async {
    try {
      if (kDebugMode) {
        print('📤 Getting user conversations');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/conversations'),
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to get conversations'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting conversations: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Check if conversation exists with venue
  static Future<Map<String, dynamic>> findExistingConversation({
    required String venueId,
    required String venueType,
  }) async {
    try {
      if (kDebugMode) {
        print('📤 Checking for existing conversation with venue: $venueId');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/conversations/find?venueId=$venueId&venueType=$venueType'),
        headers: await _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else if (response.statusCode == 404) {
        return {'success': false, 'noConversation': true};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to check conversation'};
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking conversation: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Mark conversation as read
  static Future<void> markAsRead(String conversationId) async {
    try {
      await http.put(
        Uri.parse('$_baseUrl/chat/conversations/$conversationId/read'),
        headers: await _getHeaders(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking conversation as read: $e');
      }
    }
  }

  /// Generate conversation preview text
  static String getPreviewText(String message) {
    if (message.length <= 50) return message;
    return '${message.substring(0, 50)}...';
  }

  /// Format conversation timestamp
  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}