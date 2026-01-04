import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_html/flutter_html.dart';

class SyllabusPage extends StatefulWidget {
  const SyllabusPage({super.key});

  @override
  State<SyllabusPage> createState() => _SyllabusPageState();
}

class _SyllabusPageState extends State<SyllabusPage> {
  final String getExamsUrl = 'https://rmps.apppro.in/api/get_exam';
  final String getSyllabusUrl = 'https://rmps.apppro.in/api/syllabus';

  List<dynamic> exams = [];
  dynamic selectedExam;
  List<dynamic> syllabusContent = [];
  bool isLoadingExams = true;
  bool isLoadingSyllabus = false;

  @override
  void initState() {
    super.initState();
    fetchExams();
  }

  Future<void> fetchExams() async {
    setState(() {
      isLoadingExams = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse(getExamsUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          exams = decoded;
          isLoadingExams = false;
        });

        if (exams.isNotEmpty) {
          selectedExam = exams[0];
          fetchSyllabusForExam(selectedExam['ExamId']);
        }
      } else {
        print('Failed to load exams. Status: ${response.statusCode}');
        print('Response body: ${response.body}');
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

  Future<void> fetchSyllabusForExam(String examId) async {
    setState(() {
      isLoadingSyllabus = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse(getSyllabusUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'ExamId': examId}),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          syllabusContent = decoded;
          isLoadingSyllabus = false;
        });
      } else {
        setState(() {
          syllabusContent = [];
          isLoadingSyllabus = false;
        });
        _showSnackBar(
          'Failed to load syllabus. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        syllabusContent = [];
        isLoadingSyllabus = false;
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
        title: const Text("Syllabus", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 2,
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildExamSelector(),
          const SizedBox(height: 10),
          _buildSyllabusList(),
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
              selectedExam != null && selectedExam['ExamId'] == exam['ExamId'];

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedExam = exam;
              });
              fetchSyllabusForExam(exam['ExamId']);
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
                    exam['Exam']!,
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

  Widget _buildSyllabusList() {
    if (isLoadingSyllabus) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    if (syllabusContent.isEmpty) {
      return const Expanded(
        child: Center(child: Text("No syllabus available for this exam.")),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: syllabusContent.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final subject = syllabusContent[index]['Subject'];
          final content = syllabusContent[index]['Content'] ?? ''; 

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Html(
                    data: content.toString(), 
                    style: {
                      "body": Style(
                        fontSize: FontSize(14.0),
                        lineHeight: LineHeight.em(1.5),
                      ),
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}