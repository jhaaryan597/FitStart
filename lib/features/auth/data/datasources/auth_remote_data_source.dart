// Auth Feature - Remote Data Source
// Handles API calls for authentication

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/exceptions.dart';
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
  final SharedPreferences sharedPreferences;

  static const String _baseUrlDev = 'http://localhost:3000/api/v1';
  static const String _baseUrlAndroidDevice = 'http://10.50.84.235:3000/api/v1';

  // IMPORTANT: After deploying to Railway, replace this with your Railway URL
  // Example: 'https://fitstart-backend-production.up.railway.app/api/v1'
  static const String _baseUrlProd = 'https://your-railway-app.up.railway.app/api/v1';

  AuthRemoteDataSourceImpl({
    required this.client,
    required this.sharedPreferences,
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

  Map<String, String> _headersWithAuth() {
    final token = sharedPreferences.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
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
        
        // Save JWT token
        await sharedPreferences.setString('jwt_token', data['token']);
        
        return UserModel.fromJson(data['user']);
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
        
        // Save JWT token
        await sharedPreferences.setString('jwt_token', data['token']);
        
        return UserModel.fromJson(data['user']);
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
        
        // Save JWT token
        await sharedPreferences.setString('jwt_token', data['token']);
        
        return UserModel.fromJson(data['user']);
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
      final token = sharedPreferences.getString('jwt_token');
      if (token != null) {
        await client.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: _headersWithAuth(),
        );
      }
    } finally {
      // Always remove token locally
      await sharedPreferences.remove('jwt_token');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final token = sharedPreferences.getString('jwt_token');
      
      if (token == null) {
        throw AuthException('Not authenticated');
      }

      final response = await client.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headersWithAuth(),
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
