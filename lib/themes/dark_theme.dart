import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

import 'darkColorScheme.dart';

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Color(0xFFE49C3F), // Warm yellow color

  scaffoldBackgroundColor: Colors.black, // Black background
  dividerColor: Colors.grey[800],
  colorScheme: darkColorScheme, // Apply the Light ColorScheme

  progressIndicatorTheme:  ProgressIndicatorThemeData(
    color:  Colors.grey[900], // Set color for progress indicators
    circularTrackColor: Color(0xFFE49C3F),
  ),


  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black87, // Dark gray for app bar
    iconTheme: IconThemeData(color: Colors.white), // White icons in app bar
  ),


  textTheme:const TextTheme(
    bodyLarge: TextStyle(color: Colors.white), // White text for readability
    bodyMedium: TextStyle(color: Color(0xFF888888)), // Light gray text for secondary text
    bodySmall: TextStyle(color: Colors.white), // Headline in white
    displayLarge:  TextStyle(color: Colors.white),
  ),


  cardColor: const Color(0xFF222222), // Dark gray cards for contrast
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFE49C3F), // Yellow for FAB
  ),









  iconTheme: const IconThemeData(
    color: Colors.white, // White for general icons
  ),
  // Additional adjustments for other components can be made here.
    indicatorColor:  Colors.white, // Active Tab indicator color (white for dark theme)
    unselectedWidgetColor: const Color(0xFF888888),
);
