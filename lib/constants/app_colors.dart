import 'package:flutter/material.dart';

/// Custom color palette for the PayGuardian app
/// Following the dark theme color scheme:
/// - Text: #FFFFFF (White) - Used only for text
/// - Icons: #94a3b8 (Slate gray) - For icons and secondary elements
/// - Primary background: #0b0b0b (Almost black)
/// - Card background: #040015 (Deep navy)
/// - Accent color: #2563eb (Blue for interactive elements)

class AppColors {
  // Text colors (white only)
  static const Color textPrimary = Color(0xFFFFFFFF); // White
  static const Color textSecondary = Color(0xFFFFFFFF); // White

  // Icon colors (slate gray)
  static const Color iconPrimary = Color(0xFF94a3b8); // Slate gray
  static const Color iconSecondary = Color(0xFF94a3b8); // Slate gray

  // Background colors
  static const Color background = Color(0xFF0b0b0b); // Almost black
  static const Color cardBackground = Color(0xFF040015); // Deep navy

  // Accent colors (for interactive elements, buttons, etc.)
  static const Color primary = Color(0xFF2563eb); // Blue
  static const Color accent = Color(0xFF2563eb); // Blue

  // UI element colors
  static const Color border = Color(0xFF2563eb); // Blue borders
  static const Color buttonBackground = Color(0xFF2563eb); // Blue
  static const Color buttonText = Color(0xFFFFFFFF); // White text on buttons

  // Status colors
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
}
