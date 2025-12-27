import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:FitStart/services/api_service.dart';
import 'package:permission_handler/permission_handler.dart';

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
        print('Gallery permission denied');
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
      print('Error picking image from gallery: $e');
      rethrow;
    }
  }

  // Pick image from camera
  static Future<File?> pickImageFromCamera() async {
    try {
      // Request camera permission
      final hasPermission = await _requestPermission(Permission.camera);

      if (!hasPermission) {
        print('Camera permission denied');
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
      print('Error picking image from camera: $e');
      rethrow;
    }
  }

  // Upload image to backend storage
  static Future<String?> uploadProfileImage(
      File imageFile, String userId) async {
    try {
      // TODO: Implement backend image upload endpoint
      // This should upload to cloud storage (Cloudinary, S3, etc.)
      // For now, return null indicating upload not implemented
      print('Image upload to backend not implemented yet');
      print('File: ${imageFile.path}, User: $userId');
      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Save profile image URL to database
  static Future<bool> saveProfileImageUrl(
      String userId, String imageUrl) async {
    try {
      // TODO: Backend endpoint to update profile image needs to be created
      // For now, just log the action
      print('Profile image URL saved locally: $imageUrl for user: $userId');
      return true;
    } catch (e) {
      print('Error saving profile image URL: $e');
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
      print('Error fetching profile image: $e');
      return null;
    }
  }

  // Delete old profile image from storage (optional cleanup)
  static Future<void> deleteOldProfileImage(String imageUrl) async {
    try {
      // TODO: Backend endpoint to delete old profile images needs to be created
      print('Delete old image: $imageUrl (backend endpoint needed)');
    } catch (e) {
      print('Error deleting old image: $e');
    }
  }
}
