import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raj_modern_public_school/dashboard/dashboard_screen.dart';
import 'package:raj_modern_public_school/login_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:raj_modern_public_school/notification/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    initializeNotifications();
    checkLoginStatus();
  }

  void initializeNotifications() async {
    // 🔔 Local notification setup
    NotificationService.initialize(context);

    // 🔔 Foreground notification handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📲 [Foreground] ${message.notification?.title}");
      NotificationService.display(message);
    });

    // 🔒 Permission request (needed for Android 13+)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2)); 

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', height: 120),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
