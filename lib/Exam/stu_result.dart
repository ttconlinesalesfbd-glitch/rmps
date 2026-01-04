import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StudentResultPage extends StatefulWidget {
  const StudentResultPage({Key? key}) : super(key: key);

  @override
  State<StudentResultPage> createState() => _StudentResultPageState();
}

class _StudentResultPageState extends State<StudentResultPage> {
  String? selectedExamId;
  List exams = [];
  List results = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchExams();
  }

  Future<void> fetchExams() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await http.post(
        Uri.parse('https://rmps.apppro.in/api/get_exam'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          exams = json.decode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load exams: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> fetchResults() async {
    if (selectedExamId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select an exam")));
      return;
    }

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('https://rmps.apppro.in/api/teacher/result'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'ExamId': selectedExamId}),
    );

    if (response.statusCode == 200) {
      setState(() {
        results = json.decode(response.body);
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to fetch results")));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          "Student Result",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Dropdown for Exam selection
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedExamId,
                  hint: const Text("Select Exam"),
                  isExpanded: true,
                  items: exams.map<DropdownMenuItem<String>>((exam) {
                    return DropdownMenuItem<String>(
                      value: exam['ExamId'].toString(),
                      child: Text(exam['Exam']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedExamId = value);
                    fetchResults();
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Loader
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              ),

            // Results
            if (!isLoading && results.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final student = results[index];
                    final marks = student['Marks'] as List;
                    double totalMarks = 0;
                    double obtainedMarks = 0;

                    for (var m in marks) {
                      totalMarks += double.tryParse(m['TotalMark'] ?? '0') ?? 0;
                      if (m['IsPresent'] == "Yes") {
                        obtainedMarks +=
                            double.tryParse(m['GetMark'] ?? '0') ?? 0;
                      }
                    }

                    double percentage = totalMarks > 0
                        ? (obtainedMarks / totalMarks) * 100
                        : 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "R_No: ${student['RollNo']}  ||  ${student['StudentName']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "F Name: ${student['FatherName']}",
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Subject table header (MODIFIED)
                            Row(
                              children: const [
                                // Subject column will take up most of the space
                                Expanded(
                                  flex: 3, // Increased relative size
                                  child: Text(
                                    "Subject",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Added a Spacer to separate Subject from Total
                                Spacer(),
                                // Total and Obt columns with fixed space
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    "Total",
                                    textAlign: TextAlign
                                        .right, // Align text right for numerical value
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 15,
                                ), // Reduced space between Total and Obt
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    "Obt",
                                    textAlign: TextAlign
                                        .right, // Align text right for numerical value
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            Column(
                              children: marks.map((m) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    children: [
                                      // Subject column data (MODIFIED)
                                      Expanded(
                                        flex:
                                            3, // Corresponds to the header's flex: 3
                                        child: Text(m['Subject']),
                                      ),
                                      // Added a Spacer
                                      const Spacer(),
                                      // Total Mark data (MODIFIED)
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          m['TotalMark'],
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 15,
                                      ), 
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          m['IsPresent'] == "Yes"
                                              ? m['GetMark']
                                              : "Ab",
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            color: m['IsPresent'] == "Yes"
                                                ? Colors.black
                                                : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total: ${obtainedMarks.toInt()} / ${totalMarks.toInt()}",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "Percentage: ${percentage.toStringAsFixed(2)}%",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
