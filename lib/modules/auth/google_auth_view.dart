import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:FitStart/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:FitStart/features/auth/presentation/bloc/auth_event.dart';
import 'package:FitStart/features/auth/presentation/bloc/auth_state.dart';
import 'package:FitStart/services/google_auth_service.dart';
import 'package:FitStart/modules/root/root_view.dart';
import 'package:FitStart/core/cache/cache_manager.dart';

/// A clean, minimal Google-only authentication view
/// Matches the onboarding UI style for smooth transitions
class GoogleAuthView extends StatefulWidget {
  const GoogleAuthView({Key? key}) : super(key: key);

  @override
  State<GoogleAuthView> createState() => _GoogleAuthViewState();
}

class _GoogleAuthViewState extends State<GoogleAuthView>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic));
    
    // Start animation after a brief delay for smooth transition from onboarding
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      final googleResult = await GoogleAuthService.signInWithGoogle();

      if (googleResult['success']) {
        if (mounted) {
          context.read<AuthBloc>().add(
            GoogleSignInEvent(idToken: googleResult['idToken']),
          );
        }
      } else if (googleResult['error'] != 'Sign in cancelled') {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(googleResult['error'] ?? 'Google sign in failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleGuestMode() async {
    // Set guest mode flag
    final settingsBox = await Hive.openBox('settings');
    await settingsBox.put('guest_mode', true);
    
    // Set up guest user cache
    final userBox = await Hive.openBox('user_cache');
    await userBox.put('email', 'guest@fitstart.local');
    await userBox.put('name', 'Guest User');
    await userBox.put('id', 'guest_user');
    
    // Cache guest profile
    await CacheManager.set('user_profile', {
      '_id': 'guest_user',
      'email': 'guest@fitstart.local',
      'name': 'Guest User',
      'username': 'Guest',
      'profileImage': null,
    });
    
    if (mounted) {
      // Navigate to home as guest
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
            RootView(currentScreen: 0),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is Authenticated || state is AuthSuccess) {
          // Cache user data
          if (state is Authenticated) {
            final user = state.user;
            await CacheManager.set('user_profile', {
              'username': user.username,
              'email': user.email,
              'profileImage': user.profileImage,
              'phoneNumber': user.phoneNumber,
              'id': user.id,
            });
          }
          
          // Navigate to home with smooth transition
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => 
                RootView(currentScreen: 0),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        } else if (state is AuthError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        body: Column(
          children: [
            // Top image section - matching onboarding style
            SizedBox(
              height: screenHeight * 0.55,
              width: double.infinity,
              child: Stack(
                children: [
                  // Background image
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/login.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Dark overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.5),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Header text
                  Positioned(
                    left: 24,
                    right: 24,
                    top: 0,
                    child: SafeArea(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              SizedBox(height: 20),
                              Text(
                                'Welcome to FitStart',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  shadows: [
                                    Shadow(color: Colors.black38, blurRadius: 10),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Your fitness journey begins here',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.4,
                                  shadows: [
                                    Shadow(color: Colors.black26, blurRadius: 8),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom white sheet - matching onboarding style
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo
                            Image.asset(
                              'assets/images/logo.png',
                              height: 75,
                            ),
                            const SizedBox(height: 8),
                            
                            // Title
                            const Text(
                              'Get Started',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Subtitle
                            Text(
                              'Sign in with your Google account to access\ngyms, fitness classes, and more',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Google Sign In Button
                            _isLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF92C848)),
                                  )
                                : SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _handleGoogleSignIn,
                                      icon: Image.asset(
                                        'assets/icons/google_logo.png',
                                        height: 24,
                                        width: 24,
                                        errorBuilder: (context, error, stackTrace) => 
                                          const Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
                                      ),
                                      label: const Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF92C848),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        minimumSize: const Size(double.infinity, 56),
                                        elevation: 2,
                                      ),
                                    ),
                                  ),
                            
                            const SizedBox(height: 12),
                            
                            // Skip / Guest Mode Button
                            if (!_isLoading)
                              TextButton(
                                onPressed: _handleGuestMode,
                                child: Text(
                                  'Skip for now',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            
                            const SizedBox(height: 8),
                            
                            // Terms text
                            Text(
                              'By continuing, you agree to our\nTerms of Service and Privacy Policy',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
