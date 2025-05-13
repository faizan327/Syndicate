import 'package:flutter/material.dart';
import 'package:syndicate/screen/login_screen.dart';
import 'package:syndicate/screen/signup.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showLogin = true;

  void _toggleScreen() {
    setState(() {
      _showLogin = !_showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _showLogin
        ? LoginScreen(_toggleScreen)
        : SignupScreen(_toggleScreen);
  }
}