import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:FitStart/services/api_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

class ProfileImageService {
  static final ImagePicker _picker = ImagePicker();

  // Preset avatar options
  static const List<String> presetAvatars = [
    'assets/images/user_profile_example1.png',
    'assets/images/user_profile_example2.png',
    'assets/images/user_profile_example3.png',
    'assets/images/user_profile_example4.png',
  ];

  static const String defaultAvatar = 'assets/images/profile_male.jpg';

  // Request permissions
  static Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }

  // Pick image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      // Request storage/photos permission
      bool hasPermission;
      if (Platform.isAndroid) {
        // For Android 13+, use photos permission, otherwise storage
        if (await Permission.photos.isGranted ||
            await Permission.storage.isGranted) {
          hasPermission = true;
        } else {
          hasPermission = await _requestPermission(Permission.photos) ||
              await _requestPermission(Permission.storage);
        }
      } else {
        hasPermission = await _requestPermission(Permission.photos);
      }

      if (!hasPermission) {
        if (kDebugMode) debugPrint('Gallery permission denied');
        return null;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error picking image from gallery: $e');
      rethrow;
    }
  }

  // Pick image from camera
  static Future<File?> pickImageFromCamera() async {
    try {
      // Request camera permission
      final hasPermission = await _requestPermission(Permission.camera);

      if (!hasPermission) {
        if (kDebugMode) debugPrint('Camera permission denied');
        return null;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error picking image from camera: $e');
      rethrow;
    }
  }

  // Upload image to backend storage
  static Future<String?> uploadProfileImage(
      File imageFile, String userId) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/auth/upload-profile-image'),
      );

      // Add authorization header
      final headers = await ApiService.getHeaders();
      request.headers.addAll(headers);

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', imageFile.path.split('.').last),
        ),
      );

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = jsonDecode(responseData);

      if (response.statusCode == 200 && data['success']) {
        return data['data']['profileImage'] as String?;
      } else {
        if (kDebugMode) debugPrint('Upload failed: ${data['message']}');
        return null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // Save profile image URL to database
  static Future<bool> saveProfileImageUrl(
      String userId, String imageUrl) async {
    try {
      // TODO: Backend endpoint to update profile image needs to be created
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving profile image URL: $e');
      return false;
    }
  }

  // Get user's profile image URL from database
  static Future<String?> getProfileImageUrl(String userId) async {
    try {
      final result = await ApiService.getCurrentUser();
      if (result['success']) {
        return result['data']['profileImage'] as String?;
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching profile image: $e');
      return null;
    }
  }

  // Delete old profile image from storage (optional cleanup)
  static Future<void> deleteOldProfileImage(String imageUrl) async {
    try {
      // TODO: Backend endpoint to delete old profile images needs to be created
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting old image: $e');
    }
  }
}
