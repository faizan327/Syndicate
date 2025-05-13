import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/cupertino.dart';

import 'lightColorScheme.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Color(0xFFE49C3F), // Warm yellow color

  scaffoldBackgroundColor: Colors.white, // White background
  dividerColor: Colors.grey[300],
  colorScheme: lightColorScheme, // Apply the Light ColorScheme

  progressIndicatorTheme:  ProgressIndicatorThemeData(
    color:  Colors.grey[300], // Set color for progress indicators
    circularTrackColor: Colors.orange,
  ),



  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white, // App bar using the yellow
    iconTheme: IconThemeData(color: Colors.black), // Black icons in app bar
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black), // Black text for readability
    bodyMedium: TextStyle(
        color: Color(0xFF333333)), // Soft gray text for secondary text
    bodySmall: TextStyle(color: Colors.black), // Headline in black
    displayLarge:  TextStyle(color: Colors.black),
  ),


  cardColor: const Color(0xFFEEEEEE), // Light gray cards
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFFE49C3F), // Yellow for FAB
  ),
  iconTheme: const IconThemeData(
    color: Colors.black, // Black for general icons
  ),
  indicatorColor:
      Colors.black, // Active Tab indicator color (black for light theme)
  unselectedWidgetColor:
      Colors.grey, // Unselected tab or widget color (gray for light theme)
  // Additional adjustments for other components can be made here.
);
