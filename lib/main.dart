import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(const EventWalletApp());
}

class EventWalletApp extends StatelessWidget {
  const EventWalletApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EventWallet',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const SplashScreen(),
    );
  }
}
