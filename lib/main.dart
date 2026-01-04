import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raj_modern_public_school/splash_screen.dart';
import 'package:raj_modern_public_school/dashboard/dashboard_screen.dart';
import 'package:raj_modern_public_school/teacher/teacher_dashboard_screen.dart';

/// ✅ Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 [Background] ${message.notification?.title}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final userType = prefs.getString('user_type') ?? '';

  Widget initialScreen;

  if (isLoggedIn) {
    if (userType == 'Teacher') {
      initialScreen = TeacherDashboardScreen();
    } else if (userType == 'Student') {
      initialScreen = DashboardScreen();
    } else {
      initialScreen = SplashScreen(); 
    }
  } else {
    initialScreen = SplashScreen(); 
  }

  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: initialScreen,
    );
  }
}
