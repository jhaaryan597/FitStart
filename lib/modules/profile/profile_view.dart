import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:FitStart/services/api_service.dart';
import 'package:FitStart/core/cache/cache_manager.dart';
import 'package:FitStart/modules/setting/settings_view.dart';
import 'package:FitStart/modules/notification/notification_view.dart';
import 'package:FitStart/modules/chat/chat_inbox_view.dart';
import 'package:FitStart/modules/transaction/transaction_history_view.dart';
import 'package:FitStart/modules/favorites/favorites_view.dart';
import 'package:FitStart/modules/partner/become_partner_view.dart';
import 'package:FitStart/services/profile_image_service.dart';
import 'package:FitStart/services/google_auth_service.dart';
import 'package:FitStart/services/guest_mode_service.dart';
import 'package:FitStart/theme.dart';

class ProfileView extends StatefulWidget {
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String _username = 'Loading...';
  String _email = '';
  String? _profileImageUrl;
  String? _userId;
  bool _saving = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _checkGuestMode();
    _loadProfile();
  }

  Future<void> _checkGuestMode() async {
    final isGuest = await GuestModeService.isGuestMode();
    if (isGuest && mounted) {
      final canProceed = await GuestModeService.showLoginRequiredDialog(
        context,
        feature: 'profile access',
      );
      if (!canProceed && mounted) {
        Navigator.pop(context);
      }
    }
  }

  /// Get current user ID from cache
  Future<String?> _getUserIdFromCache() async {
    try {
      // Try user_cache first
      final userBox = await Hive.openBox('user_cache');
      final cachedId = userBox.get('id') as String?;
      if (cachedId != null) return cachedId;
      
      // Try user_profile cache
      final cachedProfile = await CacheManager.get<Map<String, dynamic>>('user_profile');
      if (cachedProfile != null) {
        return cachedProfile['_id'] as String? ?? cachedProfile['id'] as String?;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadProfile() async {
    // Try to load from cache first (valid for 5 minutes)
    final cachedProfile = await CacheManager.get<Map<String, dynamic>>(
      'user_profile',
      maxAge: const Duration(minutes: 5),
    );

    if (cachedProfile != null) {
      // Use cached data
      if (mounted) {
        setState(() {
          _username = (cachedProfile['username'] as String?) ??
                     (cachedProfile['name'] as String?) ?? 'No username set';
          _email = cachedProfile['email'] ?? '';
          _profileImageUrl = cachedProfile['profileImage'] as String?;
          _userId = cachedProfile['_id'] as String? ?? cachedProfile['id'] as String?;
        });
      }
      return; // Don't fetch from API
    }

    // Cache miss or expired - fetch from API
    await _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final result = await ApiService.getCurrentUser();
      if (result['success']) {
        final data = result['data'];
        
        // Cache the profile data
        await CacheManager.set('user_profile', data);
        
        // Also save to user_cache for quick access
        final userBox = await Hive.openBox('user_cache');
        await userBox.put('id', data['_id'] ?? data['id']);
        await userBox.put('email', data['email']);
        
        if (mounted) {
          setState(() {
            _username = (data['username'] as String?) ??
                       (data['name'] as String?) ?? 'No username set';
            _email = data['email'] ?? '';
            _profileImageUrl = data['profileImage'] as String?;
            _userId = data['_id'] as String? ?? data['id'] as String?;
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
      // Get user ID from cache first (no auth required)
      String? userId = _userId ?? await _getUserIdFromCache();
      
      if (userId == null) {
        // Fallback to API only if cache is empty
        final result = await ApiService.getCurrentUser();
        if (!result['success']) {
          // Use email as fallback identifier
          userId = _email.isNotEmpty ? _email : 'local_user';
        } else {
          userId = result['data']['_id'] as String?;
        }
      }
      
      userId ??= 'local_user';
      
      // Save preset avatar path directly (no upload needed for assets)
      await ProfileImageService.saveProfileImageUrl(userId, assetPath);

      // Update cache with new profile image
      final cachedProfile = await CacheManager.get<Map<String, dynamic>>('user_profile');
      if (cachedProfile != null) {
        cachedProfile['profileImage'] = assetPath;
        await CacheManager.set('user_profile', cachedProfile);
      }

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
      // Get user ID from cache first (no auth required)
      String? userId = _userId ?? await _getUserIdFromCache();
      
      if (userId == null) {
        // Fallback to API only if cache is empty
        final result = await ApiService.getCurrentUser();
        if (!result['success']) {
          // Use email as fallback identifier
          userId = _email.isNotEmpty ? _email : 'local_user';
        } else {
          userId = result['data']['_id'] as String?;
        }
      }
      
      userId ??= 'local_user';
      _showSnack('Uploading image...');

      // Upload to backend storage
      final imageUrl =
          await ProfileImageService.uploadProfileImage(imageFile, userId);

      if (imageUrl != null) {
        // Save URL to database
        await ProfileImageService.saveProfileImageUrl(userId, imageUrl);

        // Update cache with new profile image
        final cachedProfile = await CacheManager.get<Map<String, dynamic>>('user_profile');
        if (cachedProfile != null) {
          cachedProfile['profileImage'] = imageUrl;
          await CacheManager.set('user_profile', cachedProfile);
        }

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
                
                // Name field - editable
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Email section - Google OAuth only
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.email, color: primaryColor500, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Email Address',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _email.isEmpty ? 'No email set' : _email,
                        style: TextStyle(
                          color: _email.isEmpty ? Colors.grey.shade600 : textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : () => _updateEmailViaGoogle(ctx),
                          icon: Image.asset(
                            'assets/icons/google_logo.png',
                            height: 20,
                            width: 20,
                          ),
                          label: Text(_email.isEmpty ? 'Set Email via Google' : 'Update Email via Google'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: const BorderSide(color: primaryColor500),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'For security, email changes require Google authentication',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Save button - only for name changes
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving
                        ? null
                        : () async {
                            final newName = nameController.text.trim();

                            if (newName.isEmpty) {
                              _showSnack('Name cannot be empty');
                              return;
                            }

                            setState(() => _saving = true);
                            try {
                              // Update name via API
                              final result = await ApiService.updateProfile(
                                username: newName,
                              );

                              if (result['success']) {
                                // Invalidate cache
                                await CacheManager.delete('user_profile');

                                // Update local state
                                setState(() {
                                  _username = newName;
                                });

                                if (!mounted) return;
                                Navigator.of(ctx).maybePop();
                                _showSnack('Name updated successfully!');
                              } else {
                                _showSnack('Failed to update name: ${result['message']}');
                              }
                            } catch (e) {
                              _showSnack('Error updating name: $e');
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
                        : const Text('Save Name'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Update email through Google OAuth authentication
  Future<void> _updateEmailViaGoogle(BuildContext ctx) async {
    setState(() => _saving = true);
    
    try {
      _showSnack('Initiating Google authentication...');
      
      // Start Google Sign-In process
      final googleResult = await GoogleAuthService.signInWithGoogle(forceAccountPicker: true);
      
      if (!googleResult['success']) {
        _showSnack('Google authentication failed: ${googleResult['error']}');
        return;
      }
      
      final newEmail = googleResult['email'] as String;
      final idToken = googleResult['idToken'] as String;
      
      // Send the ID token to backend for email update verification
      final result = await ApiService.updateEmailViaGoogle(
        idToken: idToken,
        newEmail: newEmail,
      );
      
      if (result['success']) {
        // Invalidate cache to force refresh
        await CacheManager.delete('user_profile');
        
        // Update local state
        setState(() {
          _email = newEmail;
        });
        
        if (!mounted) return;
        Navigator.of(ctx).maybePop();
        _showSnack('Email updated successfully via Google authentication!');
      } else {
        _showSnack('Failed to update email: ${result['message']}');
      }
    } catch (e) {
      _showSnack('Error during Google authentication: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
            icon: Icons.chat_bubble_outline,
            title: 'Messages',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ChatInboxView(),
                ),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.business_center,
            title: 'Become a Partner',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BecomePartnerView(),
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
