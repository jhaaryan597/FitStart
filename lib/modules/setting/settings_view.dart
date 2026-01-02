import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:FitStart/services/api_service.dart';
import 'package:FitStart/services/local_chat_service.dart';
import 'package:FitStart/modules/auth/google_auth_view.dart';
import 'package:FitStart/modules/setting/privacy_policy_view.dart';
import 'package:FitStart/modules/setting/support_help_view.dart';
import 'package:FitStart/modules/setting/faq_view.dart';
import 'package:FitStart/modules/setting/legal_information_view.dart';
import 'package:FitStart/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:FitStart/features/auth/presentation/bloc/auth_event.dart';
import 'package:FitStart/theme.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkBlue500),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: titleTextStyle,
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildSettingsItem(
              icon: Icons.shield_outlined,
              title: 'Privacy Policy',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyView(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              icon: Icons.headset_mic_outlined,
              title: 'Support and Help',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SupportHelpView(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              icon: Icons.help_outline,
              title: 'FAQ',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FAQView(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSettingsItem(
              icon: Icons.info_outline,
              title: 'Legal Information',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LegalInformationView(),
                  ),
                );
              },
            ),
            const Spacer(),
            // Delete Account Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  _showDeleteAccountDialog(context);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  backgroundColor: Colors.transparent,
                ),
                child: Text(
                  'Delete Account',
                  style: buttonTextStyle.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Log Out Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  // Clear chat cache before logout
                  await LocalChatService.clearAllConversations();
                  
                  final authBloc = context.read<AuthBloc>();
                  authBloc.add(LogoutEvent());
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const GoogleAuthView()),
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Log Out',
                  style: buttonTextStyle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: colorWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: darkBlue500,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: normalTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Account',
            style: titleTextStyle,
          ),
          content: Text(
            'Are you sure you want to delete your account? This action is permanent and cannot be undone.',
            style: normalTextStyle,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: normalTextStyle.copyWith(color: darkBlue300),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Call the actual delete account API
                  final result = await ApiService.deleteAccount();

                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop(); // Close the dialog

                  if (result['success']) {
                    // Clear chat cache before account deletion
                    await LocalChatService.clearAllConversations();

                    // Navigate back to auth screen
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const GoogleAuthView()),
                        (route) => false,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete account: ${result['error']}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete account: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Delete',
                style: normalTextStyle.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
