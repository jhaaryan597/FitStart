// Auth Feature - Remote Data Source
// Handles API calls for authentication

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../services/google_auth_service.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  });
  Future<UserModel> googleSignIn({required String idToken});
  Future<void> logout();
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;

  static const String _baseUrlDev = 'http://localhost:3000/api/v1';
  static const String _baseUrlAndroidDevice = 'http://10.50.84.235:3000/api/v1';

  // Railway production URL
  static const String _baseUrlProd = 'https://fitstart-backend-production.up.railway.app/api/v1';

  AuthRemoteDataSourceImpl({
    required this.client,
  });

  String get baseUrl {
    // If production URL is configured (not default), always use it
    if (_baseUrlProd != 'https://your-railway-app.up.railway.app/api/v1') {
      return _baseUrlProd;
    }

    // For development/testing
    return defaultTargetPlatform == TargetPlatform.android
        ? _baseUrlAndroidDevice
        : _baseUrlDev;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  Future<Map<String, String>> _headersWithAuth() async {
    final authBox = await Hive.openBox('fitstart_auth');
    final token = authBox.get('jwt_token') as String?;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Save user data to Hive for offline access
  Future<void> _saveUserToHive(UserModel user, String token) async {
    final authBox = await Hive.openBox('fitstart_auth');
    await authBox.put('jwt_token', token);
    await authBox.put('user_data', user.toJson());
    await authBox.put('last_login', DateTime.now().toIso8601String());
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle nested response structure
        final data = responseData['data'] ?? responseData;

        final user = UserModel.fromJson(data['user']);
        final token = data['token'];

        // Save to Hive for persistence
        await _saveUserToHive(user, token);

        return user;
      } else {
        final error = jsonDecode(response.body);
        throw AuthException(error['error'] ?? 'Login failed');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  @override
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Handle nested response structure
        final data = responseData['data'] ?? responseData;

        final user = UserModel.fromJson(data['user']);
        final token = data['token'];

        // Save to Hive for persistence
        await _saveUserToHive(user, token);

        return user;
      } else {
        final error = jsonDecode(response.body);
        throw AuthException(error['error'] ?? 'Registration failed');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }

  @override
  Future<UserModel> googleSignIn({required String idToken}) async {
    try {
      print('📤 Sending Google Sign-In request to: $baseUrl/auth/google');
      final response = await client.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: _headers,
        body: jsonEncode({
          'idToken': idToken,
        }),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // Handle nested response structure: {success: true, data: {user: ..., token: ...}}
        final data = responseData['data'] ?? responseData;
        
        // Check if data has expected fields
        if (data['token'] == null) {
          throw AuthException('Server response missing token field');
        }
        if (data['user'] == null) {
          throw AuthException('Server response missing user field');
        }
        
        final user = UserModel.fromJson(data['user']);
        final token = data['token'];
        
        // Save to Hive for persistence
        await _saveUserToHive(user, token);
        
        return user;
      } else {
        final error = jsonDecode(response.body);
        throw AuthException(error['error'] ?? 'Google sign in failed');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      print('❌ Google Sign-In error: $e');
      throw AuthException('Network error: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Optional: Call backend logout endpoint
      final authBox = await Hive.openBox('fitstart_auth');
      final token = authBox.get('jwt_token') as String?;
      if (token != null) {
        await client.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: await _headersWithAuth(),
        );
      }
    } finally {
      // Always remove token locally and disconnect from Google
      final authBox = await Hive.openBox('fitstart_auth');
      await authBox.delete('jwt_token');
      await authBox.delete('user_data');
      await authBox.delete('last_login');

      // Reset onboarding and guest mode flags so user sees onboarding again
      final settingsBox = await Hive.openBox('settings');
      await settingsBox.delete('onboarding_complete');
      await settingsBox.delete('guest_mode');

      // Sign out from Google to clear cached account
      await GoogleAuthService.signOut();
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final authBox = await Hive.openBox('fitstart_auth');
      final token = authBox.get('jwt_token') as String?;
      
      if (token == null) {
        throw AuthException('Not authenticated');
      }

      final response = await client.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: await _headersWithAuth(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data['user']);
      } else {
        throw AuthException('Failed to get current user');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: $e');
    }
  }
}
