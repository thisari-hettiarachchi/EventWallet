import 'package:flutter/material.dart';

class AppColors {
  // ===== PRIMARY THEME COLORS =====
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color primaryGreen = Color(0xFF00897B);

  static const Color primary = primaryGreen;
  static const Color secondary = primaryBlue;

  // ===== GRADIENTS =====
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, primaryBlue],
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [primaryGreen, primaryBlue],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [primaryGreen, primaryBlue],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, primaryBlue],
  );

  // ===== STATUS COLORS =====
  static const Color success = Color(0xFF2E7D32);
  static const Color info = Color(0xFF0277BD);
  static const Color warning = Color(0xFFF9A825);
  static const Color danger = Color(0xFFC62828);
  static const Color error = Colors.red;

  // ===== BACKGROUND & TEXT =====
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF1A1F36);
  static const Color textGrey = Color(0xFF4A5568);
  static const Color textLight = Colors.white;

  // ===== HELPER METHODS =====
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  static BoxShadow primaryShadow({double opacity = 0.3}) {
    return BoxShadow(
      color: primaryBlue.withValues(alpha: opacity),
      blurRadius: 20,
      offset: const Offset(0, 10),
    );
  }

  static BoxShadow cardShadow({double opacity = 0.08}) {
    return BoxShadow(
      color: Colors.black.withValues(alpha: opacity),
      blurRadius: 12,
      offset: const Offset(0, 4),
    );
  }
}
