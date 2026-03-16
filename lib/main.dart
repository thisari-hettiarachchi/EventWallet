import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'features/user/onboarding/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialization
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows)) {
    debugPrint(
      "Firebase on Windows is experimental. Skipping initialization for development.",
    );
  } else {
    try {
      await Firebase.initializeApp();
      debugPrint("Firebase initialized successfully");
    } catch (e) {
      debugPrint("Firebase initialization error: $e");
    }
  }

  // Supabase initialization
  await Supabase.initialize(
    url: 'https://tdzfarrefnpywjrggqpn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRkemZhcnJlZm5weXdqcmdncXBuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2NTA2NTIsImV4cCI6MjA4OTIyNjY1Mn0.9wm90GvRqQ6PnZbMXycfYH1ZoIELz8xwfYCy4yJ5flk',
  );

  runApp(const EventWalletApp());
}

class EventWalletApp extends StatelessWidget {
  const EventWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'EventWallet',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00897B),
              primary: const Color(0xFF00897B),
              secondary: const Color(0xFF1565C0),
              surface: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F7FA),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: false,
              backgroundColor: Color(0xFF00897B),
              foregroundColor: Colors.white,
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF00897B),
                  width: 2,
                ),
              ),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
