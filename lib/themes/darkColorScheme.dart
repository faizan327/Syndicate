import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

final ColorScheme darkColorScheme =  ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFE49C3F), // Same primary color for consistency
  secondary: Colors.black12, // Accent color
  background: Colors.black87, // Dark background
  surface: Color(0xFF222222), // Darker surfaces
  onPrimary: Color(0xFF262626), // Text/Icon on primary color
  onSecondary: Colors.white, // Text/Icon on secondary color
  onBackground: Color(0xFF262626), // Text on background
  onSurface: Colors.white, // Text/Icon on surface
  error: Colors.redAccent, // Error color
  onError: Colors.black, // Text/Icon on error color
);
