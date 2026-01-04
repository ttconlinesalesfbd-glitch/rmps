import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ResultCardPage extends StatefulWidget {
  const ResultCardPage({super.key});

  @override
  State<ResultCardPage> createState() => _ResultCardPageState();
}

class _ResultCardPageState extends State<ResultCardPage> {
  List<dynamic> exams = [];
  String? selectedExamId;
  List<dynamic> studentResults = [];
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();
  List<dynamic> filteredResults = [];
  bool showSearchBar = false;

  @override
  void initState() {
    super.initState();
    fetchExams();
    filteredResults = studentResults;
  }

  Future<void> fetchExams() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.post(
      Uri.parse("https://rmps.apppro.in/api/get_exam"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({}),
    );

    if (res.statusCode == 200) {
      setState(() => exams = jsonDecode(res.body));
    } else {
      debugPrint("Failed to fetch exams: ${res.statusCode}");
    }
  }

  Future<void> fetchResults() async {
    if (selectedExamId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an exam')));
      return;
    }

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('https://rmps.apppro.in/api/teacher/result'),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"ExamId": selectedExamId}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        studentResults = data;
        filteredResults = data;
        showSearchBar = true;
      });
    } else {
      debugPrint("Failed to fetch results: ${response.statusCode}");
    }

    setState(() => isLoading = false);
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Result"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedExamId,
                      decoration: const InputDecoration(
                        labelText: 'Select Exam',
                        border: OutlineInputBorder(),
                      ),
                      items: exams.map<DropdownMenuItem<String>>((exam) {
                        return DropdownMenuItem<String>(
                          value: exam['ExamId'].toString(),
                          child: Text(exam['Exam']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => selectedExamId = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                        ),
                        onPressed: fetchResults,
                        child: const Text(
                          'Search',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            showSearchBar
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by Student name...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (query) {
                        final filtered = studentResults.where((student) {
                          final name = (student['StudentName'] ?? '')
                              .toLowerCase();
                          final roll = (student['RollNo'] ?? '').toString();
                          return name.contains(query.toLowerCase()) ||
                              roll.contains(query.toLowerCase());
                        }).toList();

                        setState(() => filteredResults = filtered);
                      },
                    ),
                  )
                : const SizedBox.shrink(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : studentResults.isEmpty
                  ? const Center(child: Text('No results found.'))
                  : ListView.builder(
                      itemCount: filteredResults.length,
                      itemBuilder: (context, index) {
                        final student = filteredResults[index];
                        final marks = (student['Marks'] ?? []) as List;

                        int totalMarks = 0;
                        double obtainedMarks = 0;

                        for (var mark in marks) {                      
                          totalMarks += int.tryParse(mark['TotalMark']) ?? 0;                   
                          if (mark['IsPresent'] == 'Yes') {
                            obtainedMarks += double.tryParse(mark['GetMark']) ?? 0;
                          }
                        }

                        double percentage = totalMarks > 0
                            ? (obtainedMarks / totalMarks) * 100
                            : 0.0;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "R_No: ${student['RollNo']}  ||  ${student['StudentName']}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "F Name: ${_toTitleCase(student['FatherName'].toString())}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        'Subject',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Total',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Obt',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...marks.map(
                                  (m) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 5,
                                          child: Text(m['Subject']),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            m['TotalMark'],
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            m['IsPresent'] == 'No'
                                                ? 'Ab'
                                                : m['GetMark'],
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: m['IsPresent'] == 'No'
                                                  ? Colors.red
                                                  : Colors.black,
                                              fontWeight: m['IsPresent'] == 'No'
                                                  ? FontWeight.bold
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Total: $obtainedMarks / $totalMarks",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      "Percentage: ${percentage.toStringAsFixed(2)}%",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
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
