import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FitStart/modules/auth/auth_view.dart';
import 'package:FitStart/modules/onboarding/onboarding_view.dart';
import 'package:FitStart/modules/root/root_view.dart';

final authViewModelProvider = ChangeNotifierProvider((ref) => AuthViewModel());

class AuthViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> signIn(
      BuildContext context, String email, String password) async {
    _setLoading(true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (!context.mounted) return;
      if (response.user != null) {
        // After login, go directly to the main app screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => RootView(currentScreen: 0)),
        );
      }
    } on AuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
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
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.supabase.flutterquickstart://login-callback/',
        data: {'username': username},
      );
      if (!context.mounted) return;
      if (response.user != null) {
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
      }
    } on AuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
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
      await Supabase.instance.client.auth.signOut();
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
