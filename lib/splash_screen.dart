import 'dart:async';
import 'package:flutter/material.dart';
import 'onboarding_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 120,
            ),

            const SizedBox(height: 20),

            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue,
                  Colors.green,
                ],
              ).createShader(bounds),
              child: const Text(
                'EventWallet',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Manage your events and budget smartly',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: 50,
              height: 50,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CircularProgressIndicator(
                    valueColor: _controller.drive(
                      ColorTween(
                        begin: Colors.blue,
                        end: Colors.green,
                      ),
                    ),
                    strokeWidth: 4,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
