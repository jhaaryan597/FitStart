import 'package:flutter/material.dart';
import 'package:FitStart/modules/auth/auth_view.dart';
import 'package:FitStart/modules/onboarding/onboarding_view.dart';
import 'package:FitStart/modules/root/root_view.dart';
import 'package:FitStart/services/api_service.dart';
import 'package:FitStart/services/google_auth_service.dart';

// Note: This ViewModel is deprecated and kept for backward compatibility only
// Use AuthBloc from features/auth/presentation/bloc/ for new implementations
class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    _setLoading(true);
    try {
      // Sign in with Google and get ID token
      final googleResult = await GoogleAuthService.signInWithGoogle();
      
      if (!context.mounted) return;

      if (!googleResult['success']) {
        if (googleResult['error'] != 'Sign in cancelled') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(googleResult['error'] ?? 'Google sign in failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _setLoading(false);
        return;
      }

      // Send ID token to backend
      final response = await ApiService.googleSignIn(
        idToken: googleResult['idToken'],
      );

      if (!context.mounted) return;

      if (response['success']) {
        // Navigate to main app
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => RootView(currentScreen: 0)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Authentication failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    _setLoading(false);
  }

  Future<void> signIn(
      BuildContext context, String email, String password) async {
    _setLoading(true);
    try {
      final response = await ApiService.login(
        email: email,
        password: password,
      );
      if (!context.mounted) return;
      if (response['success']) {
        // After login, go directly to the main app screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => RootView(currentScreen: 0)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    _setLoading(false);
  }

  Future<void> signUp(BuildContext context, String email, String password,
      String username) async {
    _setLoading(true);
    try {
      final response = await ApiService.register(
        email: email,
        password: password,
        username: username,
      );
      if (!context.mounted) return;
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New User created'),
            backgroundColor: Colors.green,
          ),
        );
        // After signup, go to onboarding screens
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnboardingView()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Registration failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    _setLoading(false);
  }

  Future<void> signOut(BuildContext context) async {
    _setLoading(true);
    try {
      await ApiService.logout();
      await GoogleAuthService.signOut(); // Also sign out from Google
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthView()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error logging out.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    _setLoading(false);
  }
}
