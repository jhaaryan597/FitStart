import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Local chat service for storing and retrieving chat messages locally
/// Used as fallback when backend chat routes are not available
class LocalChatService {
  static const String _conversationsBoxName = 'local_conversations';
  static const String _messagesBoxName = 'local_messages';
  static const _uuid = Uuid();

  /// Initialize local chat storage
  static Future<void> init() async {
    await Hive.openBox(_conversationsBoxName);
    await Hive.openBox(_messagesBoxName);
  }

  /// Start or get existing conversation with a venue
  static Future<Map<String, dynamic>> startConversation({
    required String venueId,
    required String venueType,
    required String venueName,
    required String venueEmail,
    required String userEmail,
    String? initialMessage,
  }) async {
    try {
      final box = await Hive.openBox(_conversationsBoxName);
      
      // Check for existing conversation - now includes userEmail for uniqueness
      final existingKey = '${userEmail}_${venueId}_$venueType';
      final existing = box.get(existingKey);
      
      if (existing != null) {
        // Return existing conversation
        final conversation = Map<String, dynamic>.from(existing);
        if (kDebugMode) {
          print('✅ Found existing conversation: ${conversation['_id']}');
        }
        return {
          'success': true,
          'data': conversation,
        };
      }
      
      // Create new conversation
      final conversationId = _uuid.v4();
      final now = DateTime.now().toIso8601String();
      
      final conversation = {
        '_id': conversationId,
        'venueId': venueId,
        'venueType': venueType,
        'venueName': venueName,
        'venueEmail': venueEmail,
        'userEmail': userEmail,
        'userName': userEmail.split('@').first, // Extract username from email
        'lastMessage': initialMessage ?? '',
        'lastMessageTime': now,
        'unreadCount': 0,
        'createdAt': now,
        'updatedAt': now,
        'messages': <Map<String, dynamic>>[],
      };
      
      // Add initial message if provided
      if (initialMessage != null && initialMessage.isNotEmpty) {
        final messageId = _uuid.v4();
        conversation['messages'] = [
          {
            '_id': messageId,
            'message': initialMessage,
            'sender': 'user',
            'senderEmail': userEmail,
            'timestamp': now,
            'isRead': false,
          }
        ];
      }
      
      await box.put(existingKey, conversation);
      
      if (kDebugMode) {
        print('✅ Created new conversation: $conversationId for user: $userEmail');
      }
      
      return {
        'success': true,
        'data': conversation,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting local conversation: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Send a message in a conversation
  static Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String message,
    required String senderEmail,
    bool isVenueOwner = false,
  }) async {
    try {
      final box = await Hive.openBox(_conversationsBoxName);
      
      // Find conversation by ID
      Map<String, dynamic>? conversation;
      String? conversationKey;
      
      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null && data['_id'] == conversationId) {
          conversation = Map<String, dynamic>.from(data);
          conversationKey = key as String;
          break;
        }
      }
      
      if (conversation == null || conversationKey == null) {
        return {'success': false, 'error': 'Conversation not found'};
      }
      
      // Create new message
      final messageId = _uuid.v4();
      final now = DateTime.now().toIso8601String();
      
      final newMessage = {
        '_id': messageId,
        'message': message,
        'sender': isVenueOwner ? 'venue' : 'user',
        'senderEmail': senderEmail,
        'timestamp': now,
        'isRead': false,
      };
      
      // Add message to conversation
      final messages = List<Map<String, dynamic>>.from(conversation['messages'] ?? []);
      messages.add(newMessage);
      
      conversation['messages'] = messages;
      conversation['lastMessage'] = message;
      conversation['lastMessageTime'] = now;
      conversation['updatedAt'] = now;
      
      await box.put(conversationKey, conversation);
      
      if (kDebugMode) {
        print('✅ Message sent in conversation: $conversationId');
      }
      
      return {
        'success': true,
        'data': newMessage,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending message: $e');
      }
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get conversation by ID
  static Future<Map<String, dynamic>> getConversation(String conversationId) async {
    try {
      final box = await Hive.openBox(_conversationsBoxName);
      
      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null && data['_id'] == conversationId) {
          return {
            'success': true,
            'data': Map<String, dynamic>.from(data),
          };
        }
      }
      
      return {'success': false, 'error': 'Conversation not found'};
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting conversation: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get all user conversations (where user is the customer)
  static Future<Map<String, dynamic>> getUserConversations(String userEmail) async {
    try {
      final box = await Hive.openBox(_conversationsBoxName);
      
      final conversations = <Map<String, dynamic>>[];
      
      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null && data['userEmail'] == userEmail) {
          conversations.add(Map<String, dynamic>.from(data));
        }
      }
      
      // Sort by last message time
      conversations.sort((a, b) {
        final aTime = DateTime.tryParse(a['lastMessageTime'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['lastMessageTime'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      
      return {
        'success': true,
        'data': conversations,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting conversations: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get all owner conversations (where user is the venue owner - someone messaged them)
  static Future<Map<String, dynamic>> getOwnerConversations(String ownerEmail) async {
    try {
      final box = await Hive.openBox(_conversationsBoxName);
      
      final conversations = <Map<String, dynamic>>[];
      
      for (var key in box.keys) {
        final data = box.get(key);
        // Find conversations where the venue email matches the owner's email
        // This means someone messaged a venue owned by this user
        if (data != null && data['venueEmail'] == ownerEmail && data['userEmail'] != ownerEmail) {
          conversations.add(Map<String, dynamic>.from(data));
        }
      }
      
      // Sort by last message time
      conversations.sort((a, b) {
        final aTime = DateTime.tryParse(a['lastMessageTime'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['lastMessageTime'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      
      return {
        'success': true,
        'data': conversations,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting owner conversations: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Find existing conversation by venue
  static Future<Map<String, dynamic>> findExistingConversation({
    required String venueId,
    required String venueType,
    String? userEmail,
  }) async {
    try {
      final box = await Hive.openBox(_conversationsBoxName);
      
      // Try with userEmail key first if provided
      if (userEmail != null && userEmail.isNotEmpty) {
        final existingKey = '${userEmail}_${venueId}_$venueType';
        final existing = box.get(existingKey);
        
        if (existing != null) {
          return {
            'success': true,
            'data': Map<String, dynamic>.from(existing),
          };
        }
      }
      
      // Fallback: search all conversations for matching venue
      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null && 
            data['venueId'] == venueId && 
            data['venueType'] == venueType &&
            (userEmail == null || data['userEmail'] == userEmail)) {
          return {
            'success': true,
            'data': Map<String, dynamic>.from(data),
          };
        }
      }
      
      return {'success': false, 'noConversation': true};
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error finding conversation: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Mark conversation as read
  static Future<void> markAsRead(String conversationId) async {
    try {
      final box = await Hive.openBox(_conversationsBoxName);
      
      for (var key in box.keys) {
        final data = box.get(key);
        if (data != null && data['_id'] == conversationId) {
          final conversation = Map<String, dynamic>.from(data);
          conversation['unreadCount'] = 0;
          
          // Mark all messages as read
          final messages = List<Map<String, dynamic>>.from(conversation['messages'] ?? []);
          for (var i = 0; i < messages.length; i++) {
            messages[i]['isRead'] = true;
          }
          conversation['messages'] = messages;
          
          await box.put(key, conversation);
          break;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking as read: $e');
      }
    }
  }

  /// Clear all chat conversations (used on logout)
  static Future<void> clearAllConversations() async {
    try {
      final box = await Hive.openBox(_conversationsBoxName);
      await box.clear();
      if (kDebugMode) {
        print('🗑️ Cleared all chat conversations');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing conversations: $e');
      }
    }
  }

  /// Simulate venue owner reply (for demo purposes)
  static Future<void> simulateVenueReply({
    required String conversationId,
    required String venueEmail,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    
    final replies = [
      "Thank you for your inquiry! We'd be happy to help.",
      "Hello! How can I assist you today?",
      "Thanks for reaching out! Our team will get back to you shortly.",
      "Hi there! We appreciate your interest in our venue.",
      "Welcome! Let me know if you have any questions about our facilities.",
    ];
    
    final randomReply = replies[DateTime.now().millisecond % replies.length];
    
    await sendMessage(
      conversationId: conversationId,
      message: randomReply,
      senderEmail: venueEmail,
      isVenueOwner: true,
    );
  }
}
