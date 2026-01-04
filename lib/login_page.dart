import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raj_modern_public_school/dashboard/dashboard_screen.dart';
import 'package:raj_modern_public_school/teacher/teacher_dashboard_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String baseUrl = "https://rmps.apppro.in/api";
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  String _errorMessage = '';
  String selectedRole = 'Student';

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': idController.text.trim(),
          'password': passwordController.text.trim(),
          'type': selectedRole,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('token', data['token']);
        await prefs.setString('user_type', data['user_type']);

        if (data['user_type'] == 'Student') {
          await prefs.setString(
            'student_name',
            data['profile']['student_name'] ?? '',
          );
          await prefs.setString(
            'student_photo',
            data['profile']['student_photo'] ?? '',
          );
          await prefs.setString(
            'class_name',
            data['profile']['class_name'] ?? '',
          );
          await prefs.setString(
            'school_name',
            data['profile']['school_name'] ?? '',
          );
          await prefs.setString('section', data['profile']['section'] ?? '');
        } else if (data['user_type'] == 'Teacher') {
          await prefs.setString('teacher_name', data['profile']['name']);
          await prefs.setString('teacher_photo', data['profile']['photo']);
          await prefs.setString('teacher_class', data['profile']['class']);
          await prefs.setString('teacher_section', data['profile']['section']);
          await prefs.setString('school_name', data['profile']['school'] ?? '');
        }

        await sendFcmTokenToLaravel();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data['user_type']} Logged in successfully'),
          ),
        );

        if (data['user_type'] == 'Student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => TeacherDashboardScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage =
              data['message'] ?? "Invalid credentials. Please try again.";
        });
      }
    } catch (e) {
      print("🔴 Login Exception: $e");
      setState(() {
        _errorMessage = 'Something went wrong. Please try again later.';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> sendFcmTokenToLaravel() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final fcmToken = await FirebaseMessaging.instance.getToken();

    if (fcmToken == null) {
      print('❌ FCM token not found');
      return;
    }

    final response = await http.post(
      Uri.parse('https://rmps.apppro.in/api/save_token'),

      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'fcm_token': fcmToken}),
    );
    print("🔵 Status Code: ${response.statusCode}");
    print("📦 Response Body: ${response.body}");

    if (response.statusCode == 200) {
      print('✅ FCM token saved successfully');
    } else {
      print('❌ Failed to save FCM token: ${response.body}');
    }
  }

  void _launchURL() async {
    final Uri url = Uri.parse('https://www.techinnovationapp.in');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Widget roleToggleSwitch() {
    return Container(
      width: 250,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.grey[200],
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Student tab
          Expanded(
            child: InkWell(
              onTap: () => setState(() => selectedRole = 'Student'),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: selectedRole == 'Student'
                      ? LinearGradient(
                          colors: [Colors.purple, Colors.deepPurple],
                        )
                      : null,
                ),
                child: Text(
                  "Student",
                  style: TextStyle(
                    color: selectedRole == 'Student'
                        ? Colors.white
                        : Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Teacher tab
          Expanded(
            child: InkWell(
              onTap: () => setState(() => selectedRole = 'Teacher'),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: selectedRole == 'Teacher'
                      ? LinearGradient(
                          colors: [Colors.purple, Colors.deepPurple],
                        )
                      : null,
                ),
                child: Text(
                  "Teacher",
                  style: TextStyle(
                    color: selectedRole == 'Teacher'
                        ? Colors.white
                        : Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = selectedRole == 'Student';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.white, Colors.white]),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Image.asset('assets/images/logo.png', height: 80),
                  SizedBox(height: 10),
                  Text(
                    "RAJ MODERN PUBLIC SCHOOL",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Empowering Students, Inspiring Excellence Transforming Learning, Nurturing Futures.Smart Education for a Smarter Generation.",

                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  roleToggleSwitch(),
                  SizedBox(height: 30),

                  Text(
                    "$selectedRole Login",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: idController,
                    decoration: InputDecoration(
                      labelText: isStudent ? "Student ID" : "Teacher ID",
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => _obscureText = !_obscureText),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),

                  if (_errorMessage.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 16),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: 20),

                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        "Designed & Developed by ",
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        "TechInnovationApp",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text("Visit our website", style: TextStyle(fontSize: 12)),
                      GestureDetector(
                        onTap: _launchURL,
                        child: Text(
                          "www.techinnovationapp.in",
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
