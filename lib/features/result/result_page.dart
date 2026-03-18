import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/gradient_elevated_button.dart';

class ResultPage extends StatelessWidget {
  final bool isSuccess;
  final String message;
  final VoidCallback onButtonPressed;

  const ResultPage({
    super.key,
    required this.isSuccess,
    required this.message,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? const Color(0xFF00897B) : Colors.red;
    final bgColor = isSuccess
        ? const Color(0xFFE0F2F1)
        : const Color(0xFFFFEBEE);
    final title = isSuccess ? 'Congratulations!' : 'Error';
    final buttonText = isSuccess ? 'DONE' : 'TRY AGAIN';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00897B), Color(0xFF1565C0)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: ResultCard(
                isSuccess: isSuccess,
                message: message,
                color: color,
                bgColor: bgColor,
                title: title,
                buttonText: buttonText,
                onButtonPressed: onButtonPressed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ResultCard extends StatelessWidget {
  final bool isSuccess;
  final String message;
  final Color color;
  final Color bgColor;
  final String title;
  final String buttonText;
  final VoidCallback onButtonPressed;

  const ResultCard({
    super.key,
    required this.isSuccess,
    required this.message,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.buttonText,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300.w,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30.r,
            offset: Offset(0, 10.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 20.h,
            child: Stack(
              children: [
                ...List.generate(12, (i) => _buildDecorativeIcon(i, color)),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 20.h),
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
            child: Center(
              child: Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                child: Icon(
                  isSuccess ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 40.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          SizedBox(height: 30.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: GradientElevatedButton(
              onPressed: onButtonPressed,
              borderRadius: 12.r,
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeIcon(int index, Color color) {
    final icons = [
      Icons.close,
      Icons.circle_outlined,
      Icons.clear,
      Icons.change_history_outlined,
    ];
    final positions = [
      Offset(10.w, 10.h),
      Offset(50.w, 5.h),
      Offset(90.w, 15.h),
      Offset(130.w, 8.h),
      Offset(170.w, 20.h),
      Offset(210.w, 12.h),
      Offset(5.w, 45.h),
      Offset(220.w, 50.h),
      Offset(30.w, 55.h),
      Offset(150.w, 48.h),
      Offset(70.w, 40.h),
      Offset(190.w, 42.h),
    ];
    final opacities = [
      0.4,
      0.25,
      0.35,
      0.3,
      0.4,
      0.28,
      0.32,
      0.38,
      0.26,
      0.33,
      0.29,
      0.36,
    ];

    return Positioned(
      left: positions[index].dx,
      top: positions[index].dy,
      child: Icon(
        icons[index % icons.length],
        color: color.withValues(alpha: opacities[index]),
        size: 14.sp,
      ),
    );
  }
}
