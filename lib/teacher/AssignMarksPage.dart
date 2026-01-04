import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AssignMarksPage extends StatefulWidget {
  const AssignMarksPage({super.key});

  @override
  State<AssignMarksPage> createState() => _AssignMarksPageState();
}

class _AssignMarksPageState extends State<AssignMarksPage> {
  String? selectedExamId;
  String? selectedSubjectId;
  List exams = [];
  List subjects = [];
  List students = [];
  List filteredStudents = [];
  bool isLoading = false;
  String? message;
  String searchQuery = '';
  final TextEditingController totalMarkController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  bool isSubmitting = false;
  Map<int, TextEditingController> obtainControllers = {};

  @override
  void initState() {
    super.initState();
    fetchExams();
    fetchSubjects();
  }

  @override
  void dispose() {
    for (var controller in obtainControllers.values) {
      controller.dispose();
    }
    totalMarkController.dispose();
    super.dispose();
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

  Future<void> fetchSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final res = await http.post(
        Uri.parse("https://rmps.apppro.in/api/get_subject"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({}),
      );

      print("📨 Subjects API Response: ${res.body}");

      if (res.statusCode == 200) {
        final parsed = jsonDecode(res.body);
        setState(() => subjects = parsed);
      } else {
        debugPrint("Failed to fetch subjects: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Exception in fetchSubjects: $e");
    }
  }

  Future<void> fetchStudents() async {
    if (selectedExamId == null || selectedSubjectId == null) return;

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final res = await http.post(
        Uri.parse("https://rmps.apppro.in/api/teacher/mark"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {"ExamId": selectedExamId!, "SubjectId": selectedSubjectId!},
      );

      print("📨 Student Response: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        // Show message if any
        if (data['msg'] != null && data['msg'].toString().isNotEmpty) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Alert'),
              content: Text(data['msg']),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }

        students = List.from(data['marks'] ?? []);
        for (var s in students) {
          s['IsPresent'] = s['IsPresent'] ?? 'Yes';

          final id = s['id'];

          obtainControllers[id] = TextEditingController(
            text: s['GetMark']?.toString() ?? '',
          );
          if (students.isNotEmpty) {
            final totalMark = students.first['TotalMark']?.toString() ?? '';
            totalMarkController.text = totalMark;
          }
        }
        setState(() {
          filteredStudents = List.from(students);
          isLoading = false;
        });
      } else {
        print("❌ Error fetching students: ${res.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("❌ Exception in fetchStudents: $e");
      setState(() => isLoading = false);
    }
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

  void filterStudents(String query) {
    setState(() {
      searchQuery = query;
      filteredStudents = students
          .where(
            (student) =>
                student['StudentName'].toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                student['FatherName'].toLowerCase().contains(
                  query.toLowerCase(),
                ),
          )
          .toList();
    });
  }

  Future<void> updateMarks() async {
    // Validate marks before submitting
    for (var s in students) {
      String obtain = s['GetMark']?.toString().trim() ?? '';
      String total = s['TotalMark']?.toString().trim() ?? '';
      String name = s["StudentName"] ?? 'Unknown';

      if (obtain.isEmpty || total.isEmpty) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Missing Marks'),
            content: Text('Marks missing for $name.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      double o = double.tryParse(obtain) ?? -1;
      int t = int.tryParse(total) ?? -1;

      if (o > t) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Invalid Marks'),
            content: Text('Obtain marks is greater than Total for $name.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }

    setState(() {
      isSubmitting = true;
    });

    // Prepare submission data
    List<Map<String, dynamic>> marksData = students.map((s) {
      return {
        "StudentId": s['id'],
        "IsPresent": s['IsPresent'] ?? 'present',
        "TotalMark": int.tryParse(s['TotalMark'].toString()) ?? 0,
        "GetMark": double.tryParse(s['GetMark'].toString()) ?? 0,
      };
    }).toList();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final res = await http.post(
        Uri.parse("https://rmps.apppro.in/api/teacher/mark/store"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "ExamId": selectedExamId,
          "SubjectId": selectedSubjectId,
          "marks": marksData,
        }),
      );

      setState(() {
        isSubmitting = false;
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Submitted!"),
            content: Text(data['message'] ?? 'No message'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Error"),
            content: Text("Failed: ${res.statusCode}"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        isSubmitting = false;
      });
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Exception"),
          content: Text("❌ $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign Marks"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      DropdownButtonFormField(
                        decoration: const InputDecoration(
                          labelText: 'Select Exam',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: selectedExamId,
                        items: exams
                            .map(
                              (e) => DropdownMenuItem(
                                value: e['ExamId'],
                                child: Text(e['Exam']),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedExamId = val as String?),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField(
                        decoration: const InputDecoration(
                          labelText: 'Select Subject',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: selectedSubjectId,
                        items: subjects
                            .map(
                              (s) => DropdownMenuItem(
                                value: s['SubjectId'].toString(),
                                child: Text(s['Subject']),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedSubjectId = val),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => fetchStudents(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            "Search",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (students.isNotEmpty) ...[
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(
                    hintText: "Search student by Name",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: filterStudents,
                ),
              ],
              ...filteredStudents.map((student) {
                final hasObtainedMarks =
                    (student['GetMark']?.toString().trim().isNotEmpty ??
                        false) &&
                    student['GetMark'].toString().trim() != '0';

                final isMarked = hasObtainedMarks;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isMarked
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    border: Border.all(
                      color: isMarked
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Roll No: ${student['RollNo']} | ${student['StudentName']}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                "F Name: ${_toTitleCase(student['FatherName'].toString())}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            SizedBox(width: 5),
                            Flexible(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            student['IsPresent'] = 'Yes';
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: student['IsPresent'] == 'Yes'
                                                ? Colors.green
                                                : Colors.green[300],
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Column(
                                            children: const [
                                              Text(
                                                'P',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(height: 3),
                                              Text(
                                                'Present',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            student['IsPresent'] = 'No';
                                            student['GetMark'] = '0';
                                            final id =
                                                student['id']; // ✅ Use same id used in controller
                                            final controller =
                                                obtainControllers[id];
                                            if (controller != null) {
                                              controller.text = '0';

                                              // optional: set cursor to end
                                              controller.selection =
                                                  TextSelection.fromPosition(
                                                    TextPosition(
                                                      offset: controller
                                                          .text
                                                          .length,
                                                    ),
                                                  );
                                            }
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: student['IsPresent'] == 'No'
                                                ? Colors.red
                                                : Colors.red[200],
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Column(
                                            children: const [
                                              Text(
                                                'A',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(height: 3),
                                              Text(
                                                'Absent',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 40,
                              child: TextField(
                                controller: totalMarkController,
                                decoration: const InputDecoration(
                                  labelText: "Total Marks",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12.0,
                                    horizontal: 10.0,
                                  ),
                                ),
                                keyboardType: TextInputType.number,

                                onChanged: (val) {
                                  setState(() {
                                    for (var s in students) {
                                      s['TotalMark'] = val;
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 100,
                              height: 40,
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: "Obtain Marks",
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12.0,
                                    horizontal: 10.0,
                                  ),
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                controller: obtainControllers[student['id']],
                                onChanged: (val) {
                                  student['GetMark'] = val;

                                  setState(() {});
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              if (students.isNotEmpty)
                ElevatedButton(
                  onPressed: isSubmitting ? null : updateMarks,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Update Marks",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
            ],
          ),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
