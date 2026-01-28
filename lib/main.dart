import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/user/onboarding/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only on supported platforms
  // Windows support is experimental and may have issues
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows)) {
    debugPrint("Firebase on Windows is experimental. Skipping initialization for development.");
    // You can add a mock Firebase or alternative backend here
  } else {
    try {
      await Firebase.initializeApp();
      debugPrint("Firebase initialized successfully");
    } catch (e) {
      debugPrint("Firebase initialization error: $e");
    }
  }

  runApp(const EventWalletApp());
}

class EventWalletApp extends StatelessWidget {
  const EventWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EventWallet',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00897B),
          primary: const Color(0xFF00897B),
          secondary: const Color(0xFF1565C0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const SplashScreen(),
    );
  }
}
