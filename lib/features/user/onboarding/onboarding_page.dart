import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/gradient_elevated_button.dart';
import '../auth/welcome_back.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Plan Your Events',
      'subtitle': 'Organize weddings, parties & meetings easily.',
      'image': 'assets/images/event.png',
    },
    {
      'title': 'Track Your Budget',
      'subtitle': 'Monitor spending and stay within budget.',
      'image': 'assets/images/budget.png',
    },
    {
      'title': 'Stay Organized',
      'subtitle': 'Manage tasks and events in one place.',
      'image': 'assets/images/organized.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < onboardingData.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _restartAnimations();
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WelcomeBackPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _skip() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const WelcomeBackPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _back() {
    if (_currentIndex > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _restartAnimations();
    }
  }

  void _restartAnimations() {
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Stack(
          children: [
            // Decorative shapes
            Positioned(
              top: -80.h,
              right: -80.w,
              child: Container(
                width: 180.w,
                height: 180.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1565C0).withValues(alpha: 0.3),
                      const Color(0xFF00897B).withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100.h,
              left: -100.w,
              child: Container(
                width: 220.w,
                height: 220.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00897B).withValues(alpha: 0.2),
                      const Color(0xFF1565C0).withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),

            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: onboardingData.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                      _restartAnimations();
                    },
                    itemBuilder: (context, index) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Reduced image size
                                Image.asset(
                                  onboardingData[index]['image']!,
                                  width: 200.w,
                                  height: 200.w,
                                  fit: BoxFit.contain,
                                ),

                                SizedBox(height: 30.h),

                                // Reduced title font size
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          Color(0xFF00897B),
                                          Color(0xFF1565C0),
                                        ],
                                      ).createShader(bounds),
                                  child: Text(
                                    onboardingData[index]['title']!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5.w,
                                      height: 1.2,
                                    ),
                                  ),
                                ),

                                SizedBox(height: 12.h),

                                // Reduced subtitle font size
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                  ),
                                  child: Text(
                                    onboardingData[index]['subtitle']!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: const Color(0xFF4A5568),
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Page indicators
                Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        height: 6.h,
                        width: _currentIndex == index ? 20.w : 6.w,
                        decoration: BoxDecoration(
                          gradient: _currentIndex == index
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF00897B),
                                    Color(0xFF1565C0),
                                  ],
                                )
                              : null,
                          color: _currentIndex == index
                              ? null
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ),

                // Navigation buttons
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 16.h,
                  ),
                  child: Row(
                    children: [
                      // Back button
                      if (_currentIndex > 0)
                        Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(
                                0xFF00897B,
                              ).withValues(alpha: 0.3),
                              width: 1.5.w,
                            ),
                            color: Colors.white,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: const Color(0xFF00897B),
                              size: 16.sp,
                            ),
                            onPressed: _back,
                          ),
                        ),

                      if (_currentIndex > 0) SizedBox(width: 12.w),

                      // Next button
                      Expanded(
                        child: SizedBox(
                          height: 50.h,
                          child: GradientElevatedButton(
                            onPressed: _nextPage,
                            borderRadius: 12.r,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currentIndex == onboardingData.length - 1
                                      ? 'Get Started'
                                      : 'Next',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5.w,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Skip button
            Positioned(
              top: 10.h,
              right: 10.w,
              child: TextButton(
                onPressed: _skip,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    side: BorderSide(
                      color: const Color(0xFF00897B).withValues(alpha: 0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Skip',
                      style: TextStyle(
                        color: const Color(0xFF00897B),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.double_arrow_rounded,
                      color: const Color(0xFF00897B),
                      size: 14.sp,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
