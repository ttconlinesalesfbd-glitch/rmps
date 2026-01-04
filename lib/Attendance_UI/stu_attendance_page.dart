import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceAnalyticsPage extends StatefulWidget {
  const AttendanceAnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AttendanceAnalyticsPage> createState() =>
      _AttendanceAnalyticsPageState();
}

class _AttendanceAnalyticsPageState extends State<AttendanceAnalyticsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? analyticsData;

  @override
  void initState() {
    super.initState();
    fetchAttendanceAnalytics();
  }

  /// ✅ Move this OUTSIDE of setState()
  Map<String, dynamic> getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case "present":
        return {
          'bg': Colors.green.shade50,
          'text': Colors.green.shade700,
          'icon': Icons.check_circle,
        };
      case "absent":
        return {
          'bg': Colors.red.shade50,
          'text': Colors.red.shade700,
          'icon': Icons.cancel,
        };
      case "leave":
        return {
          'bg': Colors.yellow.shade50,
          'text': Colors.yellow.shade700,
          'icon': Icons.airline_seat_flat,
        };
      case "halfday":
        return {
          'bg': Colors.blue.shade50,
          'text': Colors.blue.shade700,
          'icon': Icons.access_time,
        };
      case "holiday":
        return {
          'bg': Colors.black54,
          'text': Colors.black26,
          'icon': Icons.celebration,
        };
      case "not_mark":
      default:
        return {
          'bg': Colors.grey.shade200,
          'text': Colors.grey.shade600,
          'icon': Icons.help_outline,
        };
    }
  }

  Future<void> fetchAttendanceAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception("No token found in SharedPreferences");

      final url = Uri.parse(
        "https://rmps.apppro.in/api/student/attendance/analytics",
      );

      final headers = {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      };

      final body = {};

      print("🟢 Sending POST request to: $url");
      final response = await http.post(url, headers: headers, body: body);

      print("🟢 Status: ${response.statusCode}");
      print("🟢 Body: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          analyticsData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load analytics");
      }
    } catch (e) {
      print("❌ Error: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = analyticsData;
     String todayStatus = (data?['today_status'] ?? 'Not Mark').toString();

    if (todayStatus.toLowerCase() == "not_mark") {
      todayStatus = "Not Mark";
    }
    final style = getStatusStyle(todayStatus);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Attendance Analysis",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
          ? const Center(child: Text("No data found"))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------------- Today's Attendance ----------------
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Today's Attendance",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: style['bg'],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  todayStatus.toUpperCase(),
                                  style: TextStyle(
                                    color: style['text'],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  style['icon'],
                                  color: style['text'],
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Text(
                            "Analytics",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ---------------- Circular Indicator ----------------
                    Center(
                      child: CircularPercentIndicator(
                        radius: 90.0,
                        lineWidth: 12.0,
                        percent: ((data['yearly_percentage'] ?? 0) / 100).clamp(
                          0.0,
                          1.0,
                        ),
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${data['yearly_percentage'] ?? 0}%",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Attendance",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        progressColor: Colors.green.shade700,
                        backgroundColor: Colors.grey.shade200,
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ---------------- Stats Cards ----------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCard(
                          "Total",
                          "${data['total_days'] ?? '-'}",
                          Colors.blue.shade100,
                          Icons.calendar_today,
                        ),
                        _buildStatCard(
                          "Present",
                          "${data['present_days'] ?? '-'}",
                          Colors.green.shade100,
                          Icons.check_circle,
                        ),
                        _buildStatCard(
                          "Absent",
                          "${data['absent_days'] ?? '-'}",
                          Colors.red.shade100,
                          Icons.cancel,
                        ),
                        _buildStatCard(
                          "Half",
                          "${data['half_days'] ?? '-'}",
                          Colors.orange.shade100,
                          Icons.accessibility_new_rounded,
                        ),
                        _buildStatCard(
                          "Leave",
                          "${data['leave_days'] ?? '-'}",
                          Colors.purple.shade100,
                          Icons.badge,
                        ),
                      ],
                    ),

                    // ---------------- Monthly Chart ----------------
                    AttendanceAnalyticsWidget(
                      monthlyData: List<Map<String, dynamic>>.from(
                        data['monthly_data'] ?? [],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black54, size: 18),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// MONTHLY CHART WIDGET
// ------------------------------------------------------------
class AttendanceAnalyticsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;

  const AttendanceAnalyticsWidget({super.key, required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Monthly Attendance %",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            const SizedBox(height: 20),

            // Bar Chart
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  maxY: 100,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 25,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 25,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < monthlyData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                monthlyData[value.toInt()]['month'],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  barGroups: monthlyData
                      .asMap()
                      .entries
                      .map(
                        (e) => BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: (e.value['percentage'] ?? 0).toDouble(),
                              color: Colors.deepPurple,
                              width: 14,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
