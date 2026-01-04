import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  DateTime _focusedMonth = DateTime.now();
  Map<String, String> _attendanceMap = {};
  bool _isLoading = false;

  Map<String, int> _calculateTotals() {
    int present = 0;
    int absent = 0;
    int leave = 0;
    int holiday = 0;
    int halfDay = 0;
    int notMarked = 0;

    _attendanceMap.forEach((date, status) {
      switch (status) {
        case 'Present':
          present++;
          break;
        case 'Absent':
          absent++;
          break;
        case 'Leave':
          leave++;
          break;
        case 'Holiday':
          holiday++;
          break;
        case 'HalfDay':
          halfDay++;
          break;
        default:
          notMarked++;
      }
    });

    return {
      'Present': present,
      'Absent': absent,
      'Leave': leave,
      'Holiday': holiday,
      'HalfDay': halfDay,
      'Not Marked': notMarked,
    };
  }

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final formattedMonth = DateFormat('yyyy-MM').format(_focusedMonth);
    final url = Uri.parse('https://rmps.apppro.in/api/student/attendance');

    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      body: {'Month': formattedMonth},
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        _attendanceMap = {for (var item in data) item['date']: item['status']};
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      print('❌ Failed to load student attendance');
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstOfMonth.weekday % 7;
    final totals = _calculateTotals();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Attendance',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 12),
              _buildCalendarContainer(year, month, daysInMonth, startWeekday),
              const SizedBox(height: 10),
              _buildSummaryBox(totals), // ✅ Updated Summary Box
            ],
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.1),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.deepPurple),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarContainer(
    int year,
    int month,
    int daysInMonth,
    int startWeekday,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          // 🔹 Month Selector
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              gradient: LinearGradient(
                colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month - 1,
                      );
                      _fetchAttendance();
                    });
                  },
                ),
                Text(
                  DateFormat.yMMMM().format(_focusedMonth),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(
                        _focusedMonth.year,
                        _focusedMonth.month + 1,
                      );
                      _fetchAttendance();
                    });
                  },
                ),
              ],
            ),
          ),

          // 🔹 Weekdays Header
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // 🔹 Calendar Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: daysInMonth + startWeekday,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemBuilder: (context, index) {
                if (index < startWeekday) return const SizedBox();

                final day = index - startWeekday + 1;
                final date = DateTime(year, month, day);
                final dateStr = DateFormat('yyyy-MM-dd').format(date);
                final status = _attendanceMap[dateStr] ?? 'Not Marked';

                Color dotColor;
                switch (status) {
                  case 'Present':
                    dotColor = Colors.green;
                    break;
                  case 'Absent':
                    dotColor = Colors.red;
                    break;
                  case 'Leave':
                    dotColor = Colors.orange;
                    break;
                  case 'Holiday':
                    dotColor = Colors.black;
                    break;
                  case 'HalfDay':
                    dotColor = Colors.blue;
                    break;
                  default:
                    dotColor = Colors.grey;
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Positioned(
                        bottom: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ✅ Summary Box (Analysis)
  Widget _buildSummaryBox(Map<String, int> totals) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusItem('Present', totals['Present']!, Colors.green),
              _buildStatusItem('Absent', totals['Absent']!, Colors.red),
              _buildStatusItem('Leave', totals['Leave']!, Colors.orange),
              _buildStatusItem('Holiday', totals['Holiday']!, Colors.black),
              _buildStatusItem('Half Day', totals['HalfDay']!, Colors.blue),
              _buildStatusItem(
                'Not Marked',
                totals['Not Marked']!,
                Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, int count, Color color) {
    return Column(
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}
