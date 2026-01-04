import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:raj_modern_public_school/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raj_modern_public_school/payment/payment_teacher_screen.dart';
import 'package:raj_modern_public_school/teacher/complaint_teacher/teacher_complaint_list_page.dart';
import 'package:raj_modern_public_school/teacher/student_list.dart';
import 'package:raj_modern_public_school/teacher/teacher_recent_homework.dart';
import 'package:raj_modern_public_school/teacher/teacher_sidebar_menu.dart';

import 'package:pie_chart/pie_chart.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  bool isLoading = true;
  int students = 0;
  int complaints = 0;
  int payments = 0;
  String schoolName = '';
  String teacherPhoto = '';

  Map<String, dynamic> attendance = {};
  List<Map<String, dynamic>> homeworks = [];

  @override
  @override
  void initState() {
    super.initState();
    loadTeacherInfo();
    fetchDashboardData().then((_) {
      fetchTeacherHomeworks(); // Add this
    });
  }

  Future<void> loadTeacherInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      schoolName = prefs.getString('school_name') ?? '';
      teacherPhoto = prefs.getString('teacher_photo') ?? '';
    });
  }

  Future<void> fetchTeacherHomeworks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('https://rmps.apppro.in/api/teacher/homework'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    print("🪪 Token being used: $token");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      // 🔍 Add these for debugging:
      print("📥 API raw response: ${response.body}");
      print("✅ Parsed data: $data");

      setState(() {
        homeworks = List<Map<String, dynamic>>.from(data);

        // 🔍 Log what's being saved
        print("📝 Homework list set in state: $homeworks");
      });
    } else {
      print('❌ Teacher Homework API failed: ${response.statusCode}');
    }
  }

  Future<void> fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('https://rmps.apppro.in/api/teacher/dashboard'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    print("🔍 Raw Response Body:");

    print(response.body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("📦 Decoded Data:");
      print(data);

      setState(() {
        students = data['students'] ?? 0;
        complaints = data['complaints'] ?? 0;
        payments = int.tryParse(data['payments'].toString()) ?? 0;
        attendance = {
          'present': data['attendances']?['present'] ?? 0,
          'absent': data['attendances']?['absent'] ?? 0,
          'leave': data['attendances']?['leave'] ?? 0,
          'half_day': data['attendances']?['half_day'] ?? 0,
          'working_days': data['attendances']?['working_days'] ?? 0,
        };
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
        if (response.statusCode == 401) {
    
      await prefs.clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );

      return;
    }
      print('Dashboard API error: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: TeacherSidebarMenu(),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.deepPurple,
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                schoolName.isNotEmpty ? schoolName : 'Teacher Dashboard',
                style: const TextStyle(color: Colors.white, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            teacherPhoto.isNotEmpty
                ? CircleAvatar(
                    backgroundImage: NetworkImage(teacherPhoto),
                    radius: 15,
                  )
                : const CircleAvatar(
                    backgroundImage: AssetImage('assets/images/logo_new.png'),
                    radius: 15,
                  ),
            const SizedBox(width: 15),
          ],
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        child: DashboardCard(
                          title: 'Students',
                          value: students.toString(),
                          borderColor: Colors.blue,
                          backgroundColor: const Color(0xFFE3F2FD),
                          textColor: Colors.blue,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => StudentListPage()),
                        ),
                      ),
                      GestureDetector(
                        child: DashboardCard(
                          title: 'Payments',
                          value: '$payments',
                          borderColor: Colors.green,
                          backgroundColor: const Color(0xFFE8F5E9),
                          textColor: Colors.green,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentTeacherScreen(),
                          ),
                        ),
                      ),
                      GestureDetector(
                        child: DashboardCard(
                          title: 'Complaints',
                          value: complaints.toString(),
                          borderColor: Colors.red,
                          backgroundColor: const Color(0xFFFFEBEE),
                          textColor: Colors.red,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeacherComplaintListPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Container(
                    height: 230,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepPurple.shade100),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.shade200, blurRadius: 6),
                      ],
                    ),
                    child: AttendancePieChart(
                      present: attendance['present'] ?? 0,
                      absent: attendance['absent'] ?? 0,
                      leave: attendance['leave'] ?? 0,
                      halfDay: attendance['half_day'] ?? 0,
                      workingDays: attendance['working_days'] ?? 0,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TeacherRecentHomeworks(homeworks: homeworks),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final Color borderColor;
  final Color backgroundColor;
  final Color textColor;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.borderColor,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 75,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class AttendancePieChart extends StatelessWidget {
  final int present;
  final int absent;
  final int leave;
  final int halfDay;
  final int workingDays;

  const AttendancePieChart({
    super.key,
    required this.present,
    required this.absent,
    required this.leave,
    required this.halfDay,
    required this.workingDays,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    // Base size that looks good on regular screens
    double baseChartRadius = 140;

    // Adjust for very small or very large screens
    double chartRadius = screenWidth < 360
        ? baseChartRadius * 0.85
        : screenWidth > 600
        ? baseChartRadius * 1.2
        : baseChartRadius;

    final Map<String, double> dataMap = {
      "Present": present.toDouble(),
      "Absent": absent.toDouble(),
      "Leave": leave.toDouble(),
      "Half Day": halfDay.toDouble(),
    };

    final List<Color> colorList = [
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.blue,
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: "📊 Today's Attendance ",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PieChart(
            dataMap: dataMap,
            chartType: ChartType.disc,
            chartRadius: chartRadius,
            colorList: colorList,
            chartValuesOptions: const ChartValuesOptions(
              showChartValueBackground: false,
              decimalPlaces: 0,
              showChartValuesInPercentage: false,
              chartValueStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            legendOptions: const LegendOptions(
              legendPosition: LegendPosition.right,
              showLegendsInRow: false,
              legendTextStyle: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
