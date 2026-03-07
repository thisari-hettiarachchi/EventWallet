import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';

/// Common app header with gradient background
/// Can be used at the top of all pages for consistency
class AppHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const AppHeader({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.pageGradientHeader,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
          child: Row(
            children: [
              if (showBackButton || leading != null)
                leading ??
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
              if (showBackButton || leading != null) SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.pageTitle,
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Header with search bar
class AppHeaderWithSearch extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final TextEditingController? searchController;
  final Function(String)? onSearchChanged;
  final String searchHint;

  const AppHeaderWithSearch({
    super.key,
    required this.title,
    this.actions,
    this.searchController,
    this.onSearchChanged,
    this.searchHint = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.pageGradientHeader,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.pageTitle,
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
            Padding(
              padding: AppSpacing.horizontalPadding,
              child: Container(
                decoration: AppDecorations.searchBar,
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  style: TextStyle(fontSize: 15.sp),
                  decoration: InputDecoration(
                    hintText: searchHint,
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15.sp),
                    prefixIcon: Icon(Icons.search, color: AppColors.primaryGreen, size: 24.sp),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}

/// Header for profile pages with avatar
class AppProfileHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final String initials;
  final Widget? statsWidget;

  const AppProfileHeader({
    super.key,
    required this.name,
    required this.subtitle,
    required this.initials,
    this.statsWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.pageGradientHeader,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(height: 20.h),
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4.w),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10.r,
                    offset: Offset(0, 5.h),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 36.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              name,
              style: AppTextStyles.whiteText(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: AppTextStyles.whiteText(fontSize: 15).copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            if (statsWidget != null) ...[
              SizedBox(height: 24.h),
              Padding(
                padding: AppSpacing.horizontalPadding,
                child: statsWidget!,
              ),
            ],
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

