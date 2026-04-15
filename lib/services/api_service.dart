import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:FitStart/core/config/api_config.dart';

/// Base API service for communicating with the Node.js backend
class ApiService {
  /// Get the base URL from centralized config
  static String get baseUrl => ApiConfig.baseUrl;

  /// Get stored JWT token
  static Future<String?> _getToken() async {
    final box = await Hive.openBox('fitstart_auth');
    return box.get('jwt_token') as String?;
  }

  /// Save JWT token
  static Future<void> _saveToken(String token) async {
    final box = await Hive.openBox('fitstart_auth');
    await box.put('jwt_token', token);
  }

  /// Remove JWT token (logout)
  static Future<void> _removeToken() async {
    final box = await Hive.openBox('fitstart_auth');
    await box.delete('jwt_token');
  }

  /// Get headers with optional authentication
  static Future<Map<String, String>> getHeaders({bool includeAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await _getToken();
      if (kDebugMode && token != null) {
        AppLogger.info('Token retrieved: Yes (${token.substring(0, 20)}...)');
      }
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ==================== AUTH ENDPOINTS ====================

  /// Register a new user
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: await getHeaders(includeAuth: false),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Save JWT token
        if (data['data']?['token'] != null) {
          await _saveToken(data['data']['token']);
        }
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: await getHeaders(includeAuth: false),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save JWT token
        if (data['data']?['token'] != null) {
          await _saveToken(data['data']['token']);
        }
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Google Sign In
  static Future<Map<String, dynamic>> googleSignIn({
    required String idToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: await getHeaders(includeAuth: false),
        body: jsonEncode({
          'idToken': idToken,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save JWT token
        if (data['data']?['token'] != null) {
          await _saveToken(data['data']['token']);
        }
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Google sign in failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Logout user
  static Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: await getHeaders(),
      );
    } catch (e) {
      AppLogger.error('Logout error', e);
    } finally {
      await _removeToken();
    }
  }

  /// Get current user profile
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to get user'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Delete user account
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/auth/me'),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Remove JWT token after successful deletion
        await _removeToken();
        return {'success': true, 'message': data['message'] ?? 'Account deleted successfully'};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to delete account'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update FCM token
  static Future<bool> updateFCMToken(String fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/fcm-token'),
        headers: await getHeaders(),
        body: jsonEncode({'token': fcmToken, 'platform': 'android'}),
      );

      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('Update FCM token error', e);
      return false;
    }
  }

  // ==================== VENUE ENDPOINTS ====================

  /// Get all venues with optional filters
  static Future<Map<String, dynamic>> getVenues({
    String? search,
    String? category,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/venues');
      
      final queryParams = <String, String>{};
      if (search != null) queryParams['search'] = search;
      if (category != null) queryParams['category'] = category;
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (minRating != null) queryParams['minRating'] = minRating.toString();

      if (queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(
        uri,
        headers: await getHeaders(includeAuth: false),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to get venues'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get venue by ID
  static Future<Map<String, dynamic>> getVenue(String venueId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/venues/$venueId'),
        headers: await getHeaders(includeAuth: false),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to get venue'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get nearby venues
  static Future<Map<String, dynamic>> getNearbyVenues({
    required double latitude,
    required double longitude,
    double maxDistance = 10.0,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/venues/nearby').replace(queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'maxDistance': maxDistance.toString(),
      });
      final response = await http.get(
        uri,
        headers: await getHeaders(includeAuth: false),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to get nearby venues'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Add venue to favorites
  static Future<bool> addToFavorites(String venueId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/venues/$venueId/favorite'),
        headers: await getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('Add to favorites error', e);
      return false;
    }
  }

  /// Remove venue from favorites
  static Future<bool> removeFromFavorites(String venueId) async {
    try {
      // Backend uses a single POST toggle endpoint for both add and remove
      final response = await http.post(
        Uri.parse('$baseUrl/venues/$venueId/favorite'),
        headers: await getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('Remove from favorites error', e);
      return false;
    }
  }

  // ==================== BOOKING ENDPOINTS ====================

  /// Get user bookings
  static Future<Map<String, dynamic>> getBookings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings'),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to get bookings'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get booking by ID
  static Future<Map<String, dynamic>> getBooking(String bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to get booking'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Create a new booking.
  /// [bookingDate] — ISO date string e.g. "2026-04-20"
  /// [timeSlots]   — list of {startTime: "10:00", endTime: "11:00"} maps
  static Future<Map<String, dynamic>> createBooking({
    required String venueId,
    required String bookingDate,
    required List<Map<String, String>> timeSlots,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings'),
        headers: await getHeaders(),
        body: jsonEncode({
          'venueId': venueId,
          'bookingDate': bookingDate,
          'timeSlots': timeSlots,
          if (notes != null) 'notes': notes,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'],
          'razorpayOrderId': data['razorpayOrderId'],
          'razorpayKeyId': data['razorpayKeyId'],
        };
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to create booking'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Cancel a booking
  static Future<bool> cancelBooking(String bookingId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
        headers: await getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('Cancel booking error', e);
      return false;
    }
  }

  /// Verify Razorpay payment
  static Future<bool> verifyPayment({
    required String bookingId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/verify-payment'),
        headers: await getHeaders(),
        body: jsonEncode({
          'razorpayPaymentId': razorpayPaymentId,
          'razorpayOrderId': razorpayOrderId,
          'razorpaySignature': razorpaySignature,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('Verify payment error', e);
      return false;
    }
  }

  // ==================== PROFILE ENDPOINTS ====================

  /// Update user profile (name, phone, etc.)
  static Future<Map<String, dynamic>> updateProfile({
    String? username,
    String? phone,
    String? profileImage,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (username != null) body['username'] = username;
      if (phone != null) body['phoneNumber'] = phone;
      if (profileImage != null) body['profileImage'] = profileImage;

      AppLogger.network('PUT', '$baseUrl/auth/update', body: body.toString());

      final headers = await getHeaders();

      final response = await http.put(
        Uri.parse('$baseUrl/auth/update'),
        headers: headers,
        body: jsonEncode(body),
      );

      AppLogger.network('Response', '$baseUrl/auth/update', statusCode: response.statusCode, body: response.body);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Update failed'};
      }
    } catch (e) {
      AppLogger.error('Update profile error', e);
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Update email via Google OAuth verification
  static Future<Map<String, dynamic>> updateEmailViaGoogle({
    required String idToken,
    required String newEmail,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/update-email-google'),
        headers: await getHeaders(),
        body: jsonEncode({
          'idToken': idToken,
          'newEmail': newEmail,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Email update failed'};
      }
    } catch (e) {
      AppLogger.error('Update email via Google error', e);
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Submit partner application
  static Future<Map<String, dynamic>> submitPartnerApplication(Map<String, dynamic> applicationData) async {
    AppLogger.info('Submitting partner application...');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/partners/apply'),
        headers: await getHeaders(),
        body: jsonEncode(applicationData),
      );

      final data = jsonDecode(response.body);

      AppLogger.network('POST', '$baseUrl/partners/apply', statusCode: response.statusCode, body: response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Application submission failed'};
      }
    } catch (e) {
      AppLogger.error('Partner application error', e);
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get partner application status
  static Future<Map<String, dynamic>> getPartnerApplicationStatus() async {
    AppLogger.info('Getting partner application status...');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/partners/my-application'),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to get application status'};
      }
    } catch (e) {
      AppLogger.error('Get partner status error', e);
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== CHAT ENDPOINTS ====================

  /// Start a new conversation
  static Future<Map<String, dynamic>> startConversation({
    required String venueId,
    required String venueType,
    required String venueName,
    required String venueEmail,
    String? initialMessage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/conversations'),
        headers: await getHeaders(),
        body: jsonEncode({
          'venueId': venueId,
          'venueType': venueType,
          'venueName': venueName,
          'venueEmail': venueEmail,
          'initialMessage': initialMessage,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        AppLogger.success('Conversation started: ${data['data']?['_id']}');
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to start conversation'};
      }
    } catch (e) {
      AppLogger.error('Error starting conversation', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Send a message in a conversation
  static Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/conversations/$conversationId/messages'),
        headers: await getHeaders(),
        body: jsonEncode({
          'message': message,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        AppLogger.success('Message sent: ${data['data']?['_id']}');
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to send message'};
      }
    } catch (e) {
      AppLogger.error('Error sending message', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get user conversations (as customer)
  static Future<Map<String, dynamic>> getUserConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/conversations/user'),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        AppLogger.success('Fetched user conversations');
        return {'success': true, 'data': data['data'] ?? []};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to fetch conversations'};
      }
    } catch (e) {
      AppLogger.error('Error fetching conversations', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get owner conversations (as venue owner)
  static Future<Map<String, dynamic>> getOwnerConversations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/conversations/owner'),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        AppLogger.success('Fetched owner conversations');
        return {'success': true, 'data': data['data'] ?? []};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to fetch conversations'};
      }
    } catch (e) {
      AppLogger.error('Error fetching owner conversations', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get a specific conversation
  static Future<Map<String, dynamic>> getConversation(String conversationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/conversations/$conversationId'),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to fetch conversation'};
      }
    } catch (e) {
      AppLogger.error('Error fetching conversation', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Mark conversation as read
  static Future<Map<String, dynamic>> markConversationAsRead(String conversationId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/chat/conversations/$conversationId/read'),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Failed to mark as read'};
      }
    } catch (e) {
      AppLogger.error('Error marking as read', e);
      return {'success': false, 'error': e.toString()};
    }
  }
}
