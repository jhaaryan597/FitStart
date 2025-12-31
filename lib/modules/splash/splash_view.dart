import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:FitStart/modules/auth/google_auth_view.dart';
import 'package:FitStart/modules/onboarding/onboarding_view.dart';
import 'package:FitStart/modules/root/root_view.dart';
import 'package:FitStart/theme.dart';

class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  _SplashViewState createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.92,
      upperBound: 1.0,
    )..repeat(reverse: true);

    // Gentle fade-in for the logo
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _visible = true);
    });

    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final settingsBox = await Hive.openBox('settings');
    final authBox = await Hive.openBox('auth');
    
    final onboardingComplete = settingsBox.get('onboarding_complete', defaultValue: false) as bool;
    final isGuestMode = settingsBox.get('guest_mode', defaultValue: false) as bool;
    final jwtToken = authBox.get('jwt_token') as String?;

    // Flow:
    // 1. If logged in (JWT token exists) -> Home
    // 2. If guest mode -> Home (with limited features)
    // 3. If onboarding not complete -> Onboarding -> Welcome (GoogleAuth)
    // 4. If onboarding complete but not logged in -> Welcome (GoogleAuth)

    if (jwtToken != null) {
      // User is logged in - go directly to home
      _navigateTo(RootView(currentScreen: 0));
    } else if (isGuestMode) {
      // Guest mode - go to home with limited features
      _navigateTo(RootView(currentScreen: 0));
    } else if (!onboardingComplete) {
      // Fresh install - show onboarding first
      _navigateTo(OnboardingView());
    } else {
      // Onboarding complete but not logged in - show Google auth (welcome)
      _navigateTo(const GoogleAuthView());
    }
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          child: ScaleTransition(
            scale: _controller,
            child: SizedBox(
              width: 140, // slightly smaller logo size
              child: Image.asset('assets/images/logo.png'),
            ),
          ),
        ),
      ),
    );
  }
}
