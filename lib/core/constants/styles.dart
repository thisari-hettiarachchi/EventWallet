import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  // ===== HEADER STYLES =====
  static const TextStyle pageTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AppColors.textLight,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    letterSpacing: -0.5,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  // ===== BODY STYLES =====
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subHeading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    color: AppColors.textGrey,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    color: AppColors.textGrey,
  );

  // ===== SPECIAL STYLES =====
  static TextStyle whiteText({double fontSize = 15, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: AppColors.textLight,
    );
  }

  static TextStyle greyText({double fontSize = 13}) {
    return TextStyle(
      fontSize: fontSize,
      color: AppColors.textGrey,
    );
  }

  static const TextStyle budgetAmount = TextStyle(
    color: AppColors.textLight,
    fontSize: 38,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
  );

  static const TextStyle statsNumber = TextStyle(
    color: AppColors.textLight,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle statsLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
}
