import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:FitStart/services/api_service.dart';
import 'package:FitStart/modules/setting/settings_view.dart';
import 'package:FitStart/modules/notification/notification_view.dart';
import 'package:FitStart/modules/transaction/transaction_history_view.dart';
import 'package:FitStart/modules/favorites/favorites_view.dart';
import 'package:FitStart/services/profile_image_service.dart';
import 'package:FitStart/theme.dart';

class ProfileView extends StatefulWidget {
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String _username = 'Loading...';
  String _email = '';
  String? _profileImageUrl;
  bool _saving = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final result = await ApiService.getCurrentUser();
      if (result['success']) {
        final data = result['data'];
        if (mounted) {
          setState(() {
            _username = (data['username'] as String?) ??
                       (data['name'] as String?) ?? 'No username set';
            _email = data['email'] ?? '';
            _profileImageUrl = data['profileImage'] as String?;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _username = 'Error fetching username';
        });
      }
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  ImageProvider _getProfileImage() {
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      // Check if it's an asset path or URL
      if (_profileImageUrl!.startsWith('assets/')) {
        return AssetImage(_profileImageUrl!);
      } else {
        return NetworkImage(_profileImageUrl!);
      }
    }
    // Default icon
    return const AssetImage(ProfileImageService.defaultAvatar);
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Select Profile Picture', style: titleTextStyle),
                const SizedBox(height: 20),
                // Preset Avatars
                Text('Choose from presets',
                    style: subTitleTextStyle.copyWith(fontSize: 14)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: ProfileImageService.presetAvatars.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _selectPresetAvatar(
                                ProfileImageService.presetAvatars[index]);
                          },
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: neonGreen, width: 2),
                              image: DecorationImage(
                                image: AssetImage(
                                    ProfileImageService.presetAvatars[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Camera Option
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: neonGreen),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImageFromCamera();
                  },
                ),
                // Gallery Option
                ListTile(
                  leading: const Icon(Icons.photo_library, color: neonGreen),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImageFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectPresetAvatar(String assetPath) async {
    setState(() {
      _uploadingImage = true;
    });

    try {
      final result = await ApiService.getCurrentUser();
      if (!result['success']) {
        _showSnack('Not authenticated');
        return;
      }

      final userId = result['data']['_id'] as String;
      // Save preset avatar path directly (no upload needed for assets)
      await ProfileImageService.saveProfileImageUrl(userId, assetPath);

      setState(() {
        _profileImageUrl = assetPath;
      });

      _showSnack('Profile picture updated!');
    } catch (e) {
      _showSnack('Error updating profile picture: $e');
    } finally {
      setState(() {
        _uploadingImage = false;
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    setState(() {
      _uploadingImage = true;
    });

    try {
      final imageFile = await ProfileImageService.pickImageFromCamera();
      if (imageFile != null) {
        await _uploadAndSaveImage(imageFile);
      }
    } catch (e) {
      _showSnack('Error picking image: $e');
    } finally {
      setState(() {
        _uploadingImage = false;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    setState(() {
      _uploadingImage = true;
    });

    try {
      final imageFile = await ProfileImageService.pickImageFromGallery();
      if (imageFile != null) {
        await _uploadAndSaveImage(imageFile);
      }
    } catch (e) {
      _showSnack('Error picking image: $e');
    } finally {
      setState(() {
        _uploadingImage = false;
      });
    }
  }

  Future<void> _uploadAndSaveImage(File imageFile) async {
    try {
      final result = await ApiService.getCurrentUser();
      if (!result['success']) {
        _showSnack('Not authenticated');
        return;
      }

      final userId = result['data']['_id'] as String;
      _showSnack('Uploading image...');

      // Upload to backend storage
      final imageUrl =
          await ProfileImageService.uploadProfileImage(imageFile, userId);

      if (imageUrl != null) {
        // Save URL to database
        await ProfileImageService.saveProfileImageUrl(userId, imageUrl);

        setState(() {
          _profileImageUrl = imageUrl;
        });

        _showSnack('Profile picture updated!');
      } else {
        _showSnack('Failed to upload image');
      }
    } catch (e) {
      _showSnack('Error uploading image: $e');
    }
  }

  Future<void> _openEditSheet() async {
    final nameController = TextEditingController(text: _username);
    final emailController = TextEditingController(text: _email);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Edit Profile', style: titleTextStyle),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    helperText: 'Changing email may require verification link.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            final newName = nameController.text.trim();
                            final newEmail = emailController.text.trim();

                            if (newName.isEmpty) {
                              _showSnack('Name cannot be empty');
                              return;
                            }

                            final oldEmail = _email;
                            final wantsEmailChange =
                                newEmail.isNotEmpty && newEmail != oldEmail;

                            setState(() => _saving = true);
                            try {
                              // Note: Backend endpoint for profile update needs to be added
                              // For now, just update local state

                              // Update local state and UI
                              setState(() {
                                _username = newName;
                                if (wantsEmailChange) _email = newEmail;
                              });

                              if (!mounted) return;
                              Navigator.of(ctx).maybePop();
                              _showSnack('Profile updated locally (backend endpoint needed)');

                              // TODO: Add backend API call when endpoint is ready
                              // await ApiService.updateProfile(username: newName, email: newEmail);
                            } catch (e) {
                              _showSnack('Error updating profile: ${e}');
                            } finally {
                              if (mounted) setState(() => _saving = false);
                            }
                          },
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Do not dispose controllers here; the bottom sheet can rebuild after hot reload.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        toolbarHeight: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: backgroundColor,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Text(
              'Profile',
              style: titleTextStyle.copyWith(fontSize: 24),
            ),
          ),

          // Profile Card
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorWhite,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: _getProfileImage(),
                      child: _uploadingImage
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: neonGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _username,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _openEditSheet,
                  icon: const Icon(Icons.edit, color: textPrimary),
                  tooltip: 'Edit Profile',
                ),
              ],
            ),
          ),

          // Menu Items
          _buildMenuItem(
            context,
            icon: Icons.sync_alt,
            title: 'Booking and Transactions',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      const TransactionHistoryView(initialTab: 1),
                ),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.favorite_border,
            title: 'Favorites',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FavoritesView(),
                ),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.notifications_none,
            title: 'Notifications',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationView(),
                ),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsView(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      decoration: BoxDecoration(
        color: colorWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: textPrimary, size: 24),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: textPrimary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        onTap: onTap,
      ),
    );
  }
}
