import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'colors.dart';

class AppTextStyles {
  // ===== HEADER STYLES =====
  static TextStyle pageTitle = TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeight.w900,
    color: AppColors.textLight,
    letterSpacing: -0.5.w,
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
    color: AppColors.textDark,
  );

  static TextStyle subHeading = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textGrey,
  );

  static TextStyle body = TextStyle(
    fontSize: 13.sp,
    color: AppColors.textDark,
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
      fontWeight: fontWeight ?? FontWeight.normal,
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
    color: AppColors.textLight,
  );
}

// ===== COMMON DECORATIONS =====
class AppDecorations {
  // Page container with gradient header
  static BoxDecoration pageGradientHeader = const BoxDecoration(
    gradient: AppColors.headerGradient,
  );

  // Rounded container for content area
  static BoxDecoration roundedContent({Color? color}) {
    return BoxDecoration(
      color: color ?? AppColors.background,
      borderRadius: BorderRadius.vertical(top: Radius.circular(35.r)),
    );
  }

  // Standard card decoration
  static BoxDecoration card({Color? color}) {
    return BoxDecoration(
      color: color ?? AppColors.cardColor,
      borderRadius: BorderRadius.circular(16.r),
      boxShadow: [AppColors.cardShadow()],
    );
  }

  // Gradient card decoration
  static BoxDecoration gradientCard = BoxDecoration(
    gradient: AppColors.cardGradient,
    borderRadius: BorderRadius.circular(16.r),
    boxShadow: [AppColors.primaryShadow(opacity: 0.3)],
  );

  // Search bar decoration
  static BoxDecoration searchBar = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12.r),
    boxShadow: [AppColors.cardShadow()],
  );

  // Transparent overlay button
  static BoxDecoration overlayButton = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.2),
    borderRadius: BorderRadius.circular(12.r),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.3),
      width: 1.w,
    ),
  );
}

// ===== COMMON PADDING & SPACING =====
class AppSpacing {
  static EdgeInsets get pagePadding => EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h);
  static EdgeInsets get horizontalPadding => EdgeInsets.symmetric(horizontal: 20.w);
  static EdgeInsets get cardPadding => EdgeInsets.all(16.r);

  static SizedBox get verticalSmall => SizedBox(height: 12.h);
  static SizedBox get verticalMedium => SizedBox(height: 20.h);
  static SizedBox get verticalLarge => SizedBox(height: 28.h);

  static SizedBox get horizontalSmall => SizedBox(width: 8.w);
  static SizedBox get horizontalMedium => SizedBox(width: 12.w);
  static SizedBox get horizontalLarge => SizedBox(width: 16.w);
}
