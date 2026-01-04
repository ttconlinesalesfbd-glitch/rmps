import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TeacherAddComplaintPage extends StatefulWidget {
  const TeacherAddComplaintPage({super.key});

  @override
  State<TeacherAddComplaintPage> createState() =>
      _TeacherAddComplaintPageState();
}

class _TeacherAddComplaintPageState extends State<TeacherAddComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  List<dynamic> students = [];
  int? selectedStudentId;
  TextEditingController descriptionController = TextEditingController();
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('https://rmps.apppro.in/api/get_student'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      setState(() {
        students = jsonDecode(response.body);
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load students")));
    }
  }

  Future<void> submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedStudentId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a student")));
      return;
    }

    setState(() => isSubmitting = true);
    print(
      '📤 Submitting: StudentId=$selectedStudentId, Description=${descriptionController.text}',
    );

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    print("📌 Sending student_id: $selectedStudentId");
    print("📌 Sending description: ${descriptionController.text.trim()}");

    final response = await http.post(
      Uri.parse('https://rmps.apppro.in/api/teacher/complaint/store'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      
      },
      body: {
        'StudentId': selectedStudentId.toString(),
        'Description': descriptionController.text.trim(),
      },
    );

    print("🔴 Status code: ${response.statusCode}");
    print("🔴 Response body: ${response.body}");

    setState(() => isSubmitting = false);

    final decoded = jsonDecode(response.body);
    if (decoded['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(decoded['message'] ?? "Complaint submitted")),
      );
      Navigator.pop(context, true); // After adding complaint successfully
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(decoded['message'] ?? "Submission failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Complaint",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedStudentId,
                isExpanded: true,
                hint: const Text("Select Student"),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                items: students.map<DropdownMenuItem<int>>((student) {
                  final displayName =
                      "${student['StudentName']} S/D/O ${student['FatherName']}";
                  return DropdownMenuItem<int>(
                    value: student['id'],
                    child: Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStudentId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Complaint Description",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter complaint description";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: isSubmitting ? null : submitComplaint,
                icon: const Icon(Icons.send),
                label: const Text("Submit"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
