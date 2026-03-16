import 'package:flutter/material.dart';
import '../core/widgets/bottom_nav.dart';

class BottomNavPage extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const BottomNavPage({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  State<BottomNavPage> createState() => _BottomNavPageState();
}

class _BottomNavPageState extends State<BottomNavPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: AppBottomNav(currentIndex: widget.currentIndex),
    );
  }
}
