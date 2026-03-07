import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../features/service_provider/dashboard/dashboard.dart';
import '../../features/service_provider/profile/profile.dart';
import '../../features/service_provider/bookings/bookings.dart';
import '../../features/service_provider/services/my_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderBottomNav extends StatelessWidget {
  final int currentIndex;

  const ProviderBottomNav({super.key, required this.currentIndex});

  Future<void> _onTap(BuildContext context, int index) async {
    if (index == currentIndex) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Widget page;
    switch (index) {
      case 0:
        final doc = await FirebaseFirestore.instance
            .collection('service_providers')
            .doc(user.uid)
            .get();
        final type = doc.data()?['providerType'] ?? 'photographer';
        page = ServiceProviderDashboard(providerId: user.uid, providerType: type);
        break;
      case 1:
        page = const ServiceProviderBookingsPage();
        break;
      case 2:
        page = const MyServicesPage();
        break;
      case 3:
        page = const ServiceProviderProfilePage();
        break;
      default:
        return;
    }

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.r,
            offset: Offset(0, -5.h),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00897B),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
        unselectedLabelStyle: TextStyle(fontSize: 12.sp),
        iconSize: 24.sp,
        elevation: 0,
        backgroundColor: Colors.transparent,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.room_service_outlined),
            activeIcon: Icon(Icons.room_service),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
