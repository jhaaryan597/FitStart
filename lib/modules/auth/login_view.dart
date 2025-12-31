import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:FitStart/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:FitStart/features/auth/presentation/bloc/auth_event.dart';
import 'package:FitStart/features/auth/presentation/bloc/auth_state.dart';
import 'package:FitStart/services/google_auth_service.dart';
import 'package:FitStart/modules/root/root_view.dart';
import 'package:FitStart/core/cache/cache_manager.dart';
import 'package:FitStart/theme.dart';

class LoginView extends StatefulWidget {
  final VoidCallback onToggleView;

  const LoginView({Key? key, required this.onToggleView}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    context.read<AuthBloc>().add(
      LoginEvent(
        email: emailController.text.trim(),
        password: passwordController.text,
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(googleResult['error'] ?? 'Google sign in failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is Authenticated || state is AuthSuccess) {
          // Cache user data for profile and home screens
          if (state is Authenticated) {
            final user = state.user;
            await CacheManager.set('user_profile', {
              'username': user.username,
              'email': user.email,
              'profileImage': user.profileImage,
              'phoneNumber': user.phoneNumber,
              'id': user.id,
            });
            print('✅ Cached user data: ${user.username}');
          }
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => RootView(currentScreen: 0),
            ),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            final screenHeight = MediaQuery.of(context).size.height;
            return Column(
              children: [
              SizedBox(
                height: screenHeight * 0.5,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/login.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.25),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black26, blurRadius: 8),
                                  ],
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Enter your email address and password to login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.3,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black26, blurRadius: 6),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Overlap the white sheet slightly over the image
              Transform.translate(
                offset: const Offset(0, -24),
                child: SizedBox(
                  // Keep total Column height within the screen: 0.5h (top) + 0.5h (bottom) = h.
                  // We still visually overlap by 24px via Transform, so no overflow occurs.
                  height: screenHeight * 0.5,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              suffixIcon: const Icon(Icons.visibility_off),
                            ),
                            obscureText: true,
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 30),
                          isLoading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF92C848),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      minimumSize: const Size(double.infinity, 50),
                                    ),
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 20),
                          // Divider with "or"
                          Row(
                            children: const [
                              Expanded(child: Divider(thickness: 1)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('or'),
                              ),
                              Expanded(child: Divider(thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Google Sign In Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: isLoading ? null : _handleGoogleSignIn,
                              icon: Image.asset(
                                'assets/icons/google_logo.png',
                                height: 24,
                                width: 24,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 24),
                              ),
                              label: const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                minimumSize: const Size(double.infinity, 50),
                                side: const BorderSide(color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: widget.onToggleView,
                            child:
                                const Text('Don\'t have an account? Sign Up'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
}