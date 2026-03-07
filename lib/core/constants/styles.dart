import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'colors.dart';

class AppTextStyles {
  // ===== HEADER STYLES =====
  static TextStyle pageTitle = TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.w900,
    color: AppColors.textLight,
  );

  static TextStyle sectionTitle = TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    letterSpacing: -0.5.w,
  );

  static TextStyle cardTitle = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  // ===== BODY STYLES =====
  static TextStyle heading = TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.bold,
  );

  static TextStyle subHeading = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
  );

  static TextStyle body = TextStyle(
    fontSize: 13.sp,
  );

  static TextStyle bodyLarge = TextStyle(
    fontSize: 15.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static TextStyle bodyMedium = TextStyle(
    fontSize: 14.sp,
    color: AppColors.textGrey,
  );

  static TextStyle bodySmall = TextStyle(
    fontSize: 12.sp,
    color: AppColors.textGrey,
  );

  // ===== SPECIAL STYLES =====
  static TextStyle whiteText({double fontSize = 14, FontWeight? fontWeight}) {
    return TextStyle(
      fontSize: fontSize.sp,
      fontWeight: fontWeight,
      color: AppColors.textLight,
    );
  }

  static TextStyle greyText({double fontSize = 12}) {
    return TextStyle(
      fontSize: fontSize.sp,
      color: AppColors.textGrey,
    );
  }

  static TextStyle budgetAmount = TextStyle(
    color: AppColors.textLight,
    fontSize: 32.sp,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.w,
  );

  static TextStyle statsNumber = TextStyle(
    color: AppColors.textLight,
    fontSize: 20.sp,
    fontWeight: FontWeight.bold,
  );

  static TextStyle statsLabel = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
  );
}
