import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // Upload image to Supabase Storage
  static Future<String?> uploadProfileImage(
      File imageFile, String userId) async {
    try {
      final String fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = 'profile_images/$fileName';

      // Upload to Supabase Storage
      await Supabase.instance.client.storage.from('avatars').upload(
          path, imageFile,
          fileOptions: const FileOptions(upsert: true));

      // Get public URL
      final String publicUrl =
          Supabase.instance.client.storage.from('avatars').getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Save profile image URL to database
  static Future<bool> saveProfileImageUrl(
      String userId, String imageUrl) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'profile_image': imageUrl}).eq('id', userId);
      return true;
    } catch (e) {
      print('Error saving profile image URL: $e');
      return false;
    }
  }

  // Get user's profile image URL from database
  static Future<String?> getProfileImageUrl(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('profile_image')
          .eq('id', userId)
          .single();

      return data['profile_image'] as String?;
    } catch (e) {
      print('Error fetching profile image: $e');
      return null;
    }
  }

  // Delete old profile image from storage (optional cleanup)
  static Future<void> deleteOldProfileImage(String imageUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(imageUrl);
      final path = uri.pathSegments.last;

      await Supabase.instance.client.storage
          .from('avatars')
          .remove(['profile_images/$path']);
    } catch (e) {
      print('Error deleting old image: $e');
    }
  }
}
