import 'package:flutter/material.dart';

class AppColors {
  // ===== PRIMARY THEME COLORS =====
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color primaryGreen = Color(0xFF00897B);

  // Use this when a single color is required
  static const Color primary = primaryBlue;

  // ===== GRADIENTS =====
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryBlue,
      primaryGreen,
    ],
  );

  // ===== STATUS COLORS =====
  static const Color secondary = Colors.blue;
  static const Color success = Colors.green;
  static const Color danger = Colors.red;

  // ===== BACKGROUND & TEXT =====
  static const Color background = Colors.white;
  static const Color textDark = Colors.black87;
  static const Color textLight = Colors.white;
}
