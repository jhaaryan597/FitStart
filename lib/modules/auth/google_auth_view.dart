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
import 'package:FitStart/utils/responsive_utils.dart';

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
    final screenHeight = ResponsiveUtils.height(context);
    final screenWidth = ResponsiveUtils.width(context);
    final isLandscape = ResponsiveUtils.isLandscape(context);

    // Responsive dimensions
    final imageHeight = ResponsiveUtils.orientation(
      context: context,
      portrait: screenHeight * 0.55,
      landscape: screenHeight * 0.7,
    );

    final titleFontSize = ResponsiveUtils.fontSize(context, isLandscape ? 28 : 32);
    final subtitleFontSize = ResponsiveUtils.fontSize(context, isLandscape ? 14 : 16);
    final buttonFontSize = ResponsiveUtils.fontSize(context, 17);
    final smallTextFontSize = ResponsiveUtils.fontSize(context, isLandscape ? 10 : 11);

    final horizontalPadding = ResponsiveUtils.spacing(context, 24);
    final verticalPadding = ResponsiveUtils.spacing(context, 24);

    return ResponsiveSafeArea(
      child: BlocListener<AuthBloc, AuthState>(
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
        child: OrientationResponsive(
          portrait: _buildPortraitLayout(
            context,
            screenHeight,
            screenWidth,
            imageHeight,
            titleFontSize,
            subtitleFontSize,
            buttonFontSize,
            smallTextFontSize,
            horizontalPadding,
            verticalPadding,
          ),
          landscape: _buildLandscapeLayout(
            context,
            screenHeight,
            screenWidth,
            imageHeight,
            titleFontSize,
            subtitleFontSize,
            buttonFontSize,
            smallTextFontSize,
            horizontalPadding,
            verticalPadding,
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    double screenHeight,
    double screenWidth,
    double imageHeight,
    double titleFontSize,
    double subtitleFontSize,
    double buttonFontSize,
    double smallTextFontSize,
    double horizontalPadding,
    double verticalPadding,
  ) {
    return Scaffold(
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
          // Top image section
          SizedBox(
            height: imageHeight,
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
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: 0,
                  child: SafeArea(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: ResponsiveUtils.spacing(context, 20)),
                            Text(
                              'Welcome to FitStart',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(color: Colors.black38, blurRadius: 10),
                                ],
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                            Text(
                              'Your fitness journey begins here',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: subtitleFontSize,
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

          // Bottom white sheet
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
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
                            height: ResponsiveUtils.responsive(
                              context: context,
                              mobile: 75,
                              tablet: 90,
                              desktop: 100,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 8)),

                          // Title
                          Text(
                            'Get Started',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(context, 24),
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.spacing(context, 8)),

                          // Subtitle
                          Text(
                            'Sign in with your Google account to access\ngyms, fitness classes, and more',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),

                          SizedBox(height: ResponsiveUtils.spacing(context, 24)),

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
                                      padding: EdgeInsets.symmetric(
                                        vertical: ResponsiveUtils.spacing(context, 16),
                                      ),
                                      minimumSize: const Size(double.infinity, 56),
                                      elevation: 2,
                                    ),
                                  ),
                                ),

                          SizedBox(height: ResponsiveUtils.spacing(context, 12)),

                          // Skip / Guest Mode Button
                          if (!_isLoading)
                            TextButton(
                              onPressed: _handleGuestMode,
                              child: Text(
                                'Skip for now',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.fontSize(context, 15),
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                          SizedBox(height: ResponsiveUtils.spacing(context, 8)),

                          // Terms text
                          Text(
                            'By continuing, you agree to our\nTerms of Service and Privacy Policy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: smallTextFontSize,
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
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    double screenHeight,
    double screenWidth,
    double imageHeight,
    double titleFontSize,
    double subtitleFontSize,
    double buttonFontSize,
    double smallTextFontSize,
    double horizontalPadding,
    double verticalPadding,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Row(
        children: [
          // Left image section
          Expanded(
            flex: 3,
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
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                // Header text
                Positioned(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: 0,
                  bottom: 0,
                  child: SafeArea(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to FitStart',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(color: Colors.black38, blurRadius: 10),
                                ],
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                            Text(
                              'Your fitness journey begins here',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: subtitleFontSize,
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

          // Right content section
          Expanded(
            flex: 2,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/logo.png',
                        height: ResponsiveUtils.responsive(
                          context: context,
                          mobile: 60,
                          tablet: 75,
                          desktop: 90,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 16)),

                      // Title
                      Text(
                        'Get Started',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 22),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.spacing(context, 8)),

                      // Subtitle
                      Text(
                        'Sign in with your Google account to access gyms, fitness classes, and more',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.fontSize(context, 13),
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),

                      SizedBox(height: ResponsiveUtils.spacing(context, 24)),

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
                                  height: 20,
                                  width: 20,
                                  errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.g_mobiledata, size: 20, color: Colors.red),
                                ),
                                label: const Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF92C848),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    vertical: ResponsiveUtils.spacing(context, 14),
                                  ),
                                  minimumSize: const Size(double.infinity, 48),
                                  elevation: 2,
                                ),
                              ),
                            ),

                      SizedBox(height: ResponsiveUtils.spacing(context, 12)),

                      // Skip / Guest Mode Button
                      if (!_isLoading)
                        TextButton(
                          onPressed: _handleGuestMode,
                          child: Text(
                            'Skip for now',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.fontSize(context, 14),
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      SizedBox(height: ResponsiveUtils.spacing(context, 8)),

                      // Terms text
                      Text(
                        'By continuing, you agree to our\nTerms of Service and Privacy Policy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: smallTextFontSize,
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
        ],
      ),
    );
  }
}
