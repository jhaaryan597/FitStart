import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class GoogleAuthService {
  // Add your Web Client ID from Google Cloud Console here
  // This is required for backend token verification
  static const String _webClientId = '112923590570-9mtmf3mj0jj0nitt3n2v1hcian1jb458.apps.googleusercontent.com';
  
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Important: Add server client ID for backend verification
    serverClientId: _webClientId,
  );

  /// Sign in with Google and return the ID token
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      developer.log('Starting Google Sign-In...');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      developer.log('Google Sign-In completed. User: ${googleUser?.email}');
      
      if (googleUser == null) {
        // User canceled the sign-in
        developer.log('Google Sign-In cancelled by user');
        return {
          'success': false,
          'error': 'Sign in cancelled',
        };
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Get the ID token
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        return {
          'success': false,
          'error': 'Failed to get ID token',
        };
      }

      return {
        'success': true,
        'idToken': idToken,
        'email': googleUser.email,
        'displayName': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
      };
    } on PlatformException catch (e) {
      developer.log('PlatformException during Google Sign-In: ${e.code} - ${e.message}');
      String errorMessage = 'Failed to sign in with Google';
      
      if (e.code == 'sign_in_failed') {
        errorMessage = 'Sign in failed. Please check your Google Cloud Console configuration.';
      } else if (e.code == 'network_error') {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.code == 'sign_in_canceled') {
        errorMessage = 'Sign in cancelled';
      }
      
      return {
        'success': false,
        'error': '$errorMessage (Code: ${e.code})',
      };
    } catch (error) {
      developer.log('Error during Google Sign-In: $error');
      return {
        'success': false,
        'error': error.toString(),
      };
    }
  }

  /// Sign out from Google
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      print('Error signing out: $error');
    }
  }

  /// Check if user is currently signed in with Google
  static Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Get current Google user
  static GoogleSignInAccount? getCurrentUser() {
    return _googleSignIn.currentUser;
  }
}
