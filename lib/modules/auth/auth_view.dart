import 'package:flutter/material.dart';
import 'package:FitStart/modules/auth/login_view.dart';
import 'package:FitStart/modules/auth/signup_view.dart';

class AuthView extends StatefulWidget {
  const AuthView({Key? key}) : super(key: key);

  @override
  _AuthViewState createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  bool _isLoginView = true;

  void _toggleView() {
    setState(() {
      _isLoginView = !_isLoginView;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoginView
        ? LoginView(onToggleView: _toggleView)
        : SignupView(onToggleView: _toggleView);
  }
}
