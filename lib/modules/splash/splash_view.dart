import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FitStart/modules/auth/auth_view.dart';
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

    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // User is logged in.
      // If they also completed onboarding, go to home.
      // Otherwise, this case shouldn't happen, but we send to home as a fallback.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => RootView(currentScreen: 0)),
      );
    } else {
      // User is not logged in.
      // If they haven't completed onboarding, show it.
      // Otherwise, show the auth screen.
      if (onboardingComplete) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthView()),
        );
      } else {
        // This is a fresh install for a new user.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnboardingView()),
        );
      }
    }
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
