import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Exam {
  final String id;
  final String name;

  Exam({required this.id, required this.name});
}

class ExamScheduleItem {
  final String subject;
  final String date;
  final String day;
  final String time;
  final String endTime;
  final String remark;

  ExamScheduleItem({
    required this.subject,
    required this.date,
    required this.day,
    required this.time,
    required this.endTime,
    required this.remark,
  });
}

class ExamSchedulePage extends StatefulWidget {
  const ExamSchedulePage({super.key});

  @override
  State<ExamSchedulePage> createState() => _ExamSchedulePageState();
}

class _ExamSchedulePageState extends State<ExamSchedulePage> {
  // API Endpoints
  final String getExamsUrl = 'https://rmps.apppro.in/api/get_exam';
  final String getScheduleUrl =
      'https://rmps.apppro.in/api/schedule'; // ✅ Changed API

  List<Exam> exams = [];
  Exam? selectedExam;
  List<ExamScheduleItem> scheduleContent = [];
  bool isLoadingExams = true;
  bool isLoadingSchedule = false;

  @override
  void initState() {
    super.initState();
    fetchExams();
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Authentication token not found. Please log in.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Future<void> fetchExams() async {
    setState(() {
      isLoadingExams = true;
    });

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(getExamsUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);

        // Convert dynamic list to Exam model list
        final loadedExams = decoded
            .map((e) => Exam(id: e['ExamId'], name: e['Exam']))
            .toList();

        setState(() {
          exams = loadedExams;
          isLoadingExams = false;
        });

        if (exams.isNotEmpty) {
          selectedExam = exams.first;
          fetchScheduleForExam(selectedExam!.id);
        }
      } else {
        print('Failed to load exams. Status: ${response.statusCode}');
        setState(() {
          isLoadingExams = false;
        });
        _showSnackBar('Failed to load exams.');
      }
    } catch (e) {
      print('Error fetching exams: $e');
      setState(() {
        isLoadingExams = false;
      });
      _showSnackBar('An error occurred: $e');
    }
  }

  Future<void> fetchScheduleForExam(String examId) async {
    setState(() {
      isLoadingSchedule = true;
      scheduleContent = [];
    });

    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(getScheduleUrl),
        headers: headers,
        body: jsonEncode({'ExamId': examId}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);

        final loadedSchedule = decoded
            .map(
              (item) => ExamScheduleItem(
                subject: item['Subject'] ?? '',
                date: item['Date'] ?? '',
                day: item['Day'] ?? '',
                time: item['Time'] ?? '',
                endTime: item['EndTime'] ?? '',
                remark: item['Remark'] ?? '',
              ),
            )
            .toList();

        setState(() {
          scheduleContent = loadedSchedule;
          isLoadingSchedule = false;
        });
      } else {
        setState(() {
          scheduleContent = [];
          isLoadingSchedule = false;
        });
        _showSnackBar(
          'Failed to load schedule. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        scheduleContent = [];
        isLoadingSchedule = false;
      });
      _showSnackBar('An error occurred: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Exam Schedule",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildExamSelector(),
          const SizedBox(height: 10),
          _buildScheduleList(),
        ],
      ),
    );
  }

  Widget _buildExamSelector() {
    if (isLoadingExams) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.deepPurple),
      );
    }

    if (exams.isEmpty) {
      return const Center(child: Text("No exams available."));
    }

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: exams.length,
        itemBuilder: (context, index) {
          final exam = exams[index];
          final isSelected =
              selectedExam != null && selectedExam!.id == exam.id;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedExam = exam;
              });
              fetchScheduleForExam(exam.id);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepPurple : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple, width: 1.2),
              ),
              child: Row(
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    exam.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleList() {
    if (isLoadingSchedule) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    if (scheduleContent.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            selectedExam == null
                ? "Select an exam to view the schedule."
                : "No schedule available for ${selectedExam!.name}.",
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: scheduleContent.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final item = scheduleContent[index];
          return _buildScheduleCard(item);
        },
      ),
    );
  }

  Widget _buildScheduleCard(ExamScheduleItem item) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject Name
            Text(
              item.subject,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const Divider(height: 16),

            // Date and Day
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Date',
              value: item.date,
            ),
            _buildInfoRow(
              icon: Icons.calendar_view_day,
              label: 'Day',
              value: item.day,
            ),

            // Time and Remark
            _buildInfoRow(
              icon: Icons.access_time,
              label: 'Time',
              value: '${item.time} - ${item.endTime}',
            ),
            _buildInfoRow(
              icon: Icons.info_outline,
              label: 'Remark',
              value: item.remark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.deepPurple),
          const SizedBox(width: 10),
          SizedBox(
            width: 80, 
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
