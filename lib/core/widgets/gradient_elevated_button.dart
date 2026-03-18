import 'package:flutter/material.dart';

import '../constants/colors.dart';

class GradientElevatedButton extends StatelessWidget {
  const GradientElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding,
    this.borderRadius = 12,
    this.gradient,
    this.boxShadow,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient:
            enabled
                ? (gradient ?? AppColors.headerGradient)
                : LinearGradient(
                  colors: [Colors.grey.shade400, Colors.grey.shade500],
                ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow:
            enabled
                ? (boxShadow ??
                    [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ])
                : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: child,
      ),
    );
  }
}

