import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:raj_modern_public_school/connect_teacher/teacher_chat.dart';
import 'package:shared_preferences/shared_preferences.dart';



class TeacherChatStudentListPage extends StatefulWidget {
  const TeacherChatStudentListPage({Key? key}) : super(key: key);

  @override
  State<TeacherChatStudentListPage> createState() =>
      _TeacherChatStudentListPageState();
}

class _TeacherChatStudentListPageState
    extends State<TeacherChatStudentListPage> {
  List<dynamic> students = [];
  List<dynamic> filteredStudents = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception("No token found in SharedPreferences");
      }

      final response = await http.post(
        Uri.parse("https://rmps.apppro.in/api/teacher/student/list"),
        headers: {"Authorization": "Bearer $token"},
        body: {"type": "all"},
      );

      print("🟢 Status: ${response.statusCode}");
      print("🟢 Body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          students = data;
          filteredStudents = data;
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch student list");
      }
    } catch (e) {
      print("❌ Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterStudents(String query) {
    setState(() {
      searchQuery = query;
      filteredStudents = students
          .where(
            (student) => student['StudentName']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: _isSearching
            ? TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: const InputDecoration(
                  hintText: 'Search student...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: _filterStudents,
              )
            : const Text(
                "Students Chat",
                style: TextStyle(color: Colors.white),
              ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  filteredStudents = students;
                  searchQuery = '';
                }
              });
            },
          ),
          
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredStudents.isEmpty
          ? const Center(
              child: Text(
                "No students found",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                return _buildStudentCard(student);
              },
            ),
    );
  }

  Widget _buildStudentCard(dynamic student) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1.5,
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeacherChatScreen(
                studentId: student['id'],
                studentName: student['StudentName'] ?? 'Unknown',
                studentPhoto: student['StudentPhoto'] ?? '',
              ),
            ),
          );
        },

        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: NetworkImage(student['StudentPhoto'] ?? ''),
          onBackgroundImageError: (_, __) {},
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                student['StudentName'] ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
            if (student['RollNo'] != null)
              Text(
                "Roll No: ${student['RollNo']}",
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              "DOB: ${student['DOB'] ?? 'N/A'}",
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 2),
            Text(
              "Father: ${student['FatherName'] ?? ''}",
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.chat_bubble_outline,
          color: Colors.deepPurple,
        ),
      ),
    );
  }
}
