import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:FitStart/modules/setting/privacy_policy_view.dart';
import 'package:FitStart/modules/setting/support_help_view.dart';
import 'package:FitStart/modules/setting/faq_view.dart';
import 'package:FitStart/modules/setting/legal_information_view.dart';
import 'package:FitStart/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:FitStart/features/auth/presentation/bloc/auth_event.dart';
import 'package:FitStart/features/auth/presentation/bloc/auth_state.dart';
import 'package:FitStart/services/guest_mode_service.dart';
import 'package:FitStart/services/google_auth_service.dart';
import 'package:FitStart/theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _isGuestMode = false;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _loadGuestMode();
  }

  Future<void> _loadGuestMode() async {
    final isGuest = await GuestModeService.isGuestMode();
    if (!mounted) return;

    setState(() {
      _isGuestMode = isGuest;
    });
  }

  Future<void> _handleGuestGoogleSignIn() async {
    if (_isSigningIn) return;

    setState(() {
      _isSigningIn = true;
    });

    try {
      final googleResult = await GoogleAuthService.signInWithGoogle();

      if (!mounted) return;

      if (googleResult['success'] == true) {
        context.read<AuthBloc>().add(
              GoogleSignInEvent(idToken: googleResult['idToken']),
            );
      } else {
        setState(() {
          _isSigningIn = false;
        });

        final error = googleResult['error'] as String?;
        if (error != null && error != 'Sign in Cancelled') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSigningIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (!_isSigningIn) return;

        if (state is Authenticated || state is AuthSuccess) {
          await GuestModeService.exitGuestMode();
          if (!mounted) return;

          setState(() {
            _isGuestMode = false;
            _isSigningIn = false;
          });
        } else if (state is AuthError) {
          if (!mounted) return;

          setState(() {
            _isSigningIn = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
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
              const SizedBox(height: 30),
              // Guest/Logout primary action
              SizedBox(
                width: double.infinity,
                height: 56,
                child: _isGuestMode
                    ? ElevatedButton.icon(
                        onPressed:
                            _isSigningIn ? null : _handleGuestGoogleSignIn,
                        icon: Image.asset(
                          'assets/icons/google_logo.png',
                          height: 24,
                          width: 24,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.g_mobiledata,
                                  color: Colors.white),
                        ),
                        label: Text(
                          _isSigningIn
                              ? 'Signing in...'
                              : 'Continue with Google',
                          style: buttonTextStyle.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF92C848),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          final authBloc = context.read<AuthBloc>();
                          authBloc.add(LogoutEvent());
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
}
