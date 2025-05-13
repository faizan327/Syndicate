import 'package:flutter/material.dart';
import 'dart:async'; // For Timer
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Wait for 3 seconds, then navigate to the MainPage
    Timer(const Duration(seconds: 1), () {
      Navigator.pushReplacementNamed(context, '/main'); // Navigate to MainPage after 1 second
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Get screen dimensions for dynamic image sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/syn.png', // Your splash screen logo
                width: screenWidth * 0.8, // 50% of screen width
                height: screenHeight * 0.8, // 30% of screen height
                fit: BoxFit.contain, // Maintain aspect ratio
              ),
              SizedBox(height: 20.h), // Scale spacing

            ],
          ),
        ),
      ),
    );
  }
}