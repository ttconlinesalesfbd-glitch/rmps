import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StudentAlertPage extends StatefulWidget {
  const StudentAlertPage({super.key});

  @override
  State<StudentAlertPage> createState() => _StudentAlertPageState();
}

class _StudentAlertPageState extends State<StudentAlertPage> {
  TextEditingController searchController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  List<dynamic> students = [];
  List<dynamic> filteredStudents = [];
  Set<String> selectedStudentIds = {};

  bool isLoading = false;
  bool isSending = false; // 🔥 NEW → Loader for Send Button
  bool selectAll = false;
  String? token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchStudents();
  }

  Future<void> _loadTokenAndFetchStudents() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
    await fetchStudents();
  }

  Future<void> fetchStudents() async {
    if (token == null) return;

    setState(() => isLoading = true);

    final url = Uri.parse(
      "https://rmps.apppro.in/api/teacher/student/list",
    );

    try {
      final res = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({}),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);

        setState(() {
          students = data;
          filteredStudents = data;
        });
      }
    } catch (e) {
      debugPrint("Error fetching students = $e");
    }

    setState(() => isLoading = false);
  }

  void filterStudents(String query) {
    setState(() {
      filteredStudents = students
          .where(
            (s) => s["StudentName"].toString().toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  // ====================================================
  // 🔴 SEND ALERT (Loader Added)
  // ====================================================
  Future<void> sendAlert() async {
    final message = descriptionController.text.trim();
    if (message.isEmpty || selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Please enter message and select students"),
        ),
      );
      return;
    }

    // Start Loader
    setState(() => isSending = true);

    // Collect tokens
    List<String> tokens = [];
    for (var student in students) {
      if (selectedStudentIds.contains(student["id"].toString())) {
        if (student["fcm_token"] != null && student["fcm_token"] != "") {
          tokens.add(student["fcm_token"]);
        }
      }
    }

    if (tokens.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠️ No FCM token found")));
      setState(() => isSending = false);
      return;
    }

    final body = {"message": message, "tokens": tokens};

    final url = Uri.parse(
      "https://rmps.apppro.in/api/teacher/student/alert",
    );

    try {
      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(body),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Alert Sent Successfully")),
        );

        descriptionController.clear();
        setState(() {
          selectAll = false;
          selectedStudentIds.clear();
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Failed : ${res.body}")));
      }
    } catch (e) {
      debugPrint("Error sending alert = $e");
    }

    // Stop Loader
    setState(() => isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Alert"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // MESSAGE BOX
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Write alert message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // SEARCH BOX
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterStudents,
                    decoration: InputDecoration(
                      hintText: "Search Student...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // SELECT ALL
                Row(
                  children: [
                    Checkbox(
                      value: selectAll,
                      onChanged: (val) {
                        setState(() {
                          selectAll = val ?? false;
                          if (selectAll) {
                            selectedStudentIds = filteredStudents
                                .map((s) => s["id"].toString())
                                .toSet();
                          } else {
                            selectedStudentIds.clear();
                          }
                        });
                      },
                    ),
                    const Text("Select All Students"),
                  ],
                ),

                // STUDENT LIST
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      final id = student["id"].toString();
                      final isChecked = selectedStudentIds.contains(id);

                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: isChecked,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  selectedStudentIds.add(id);
                                } else {
                                  selectedStudentIds.remove(id);
                                }
                                selectAll =
                                    selectedStudentIds.length ==
                                    filteredStudents.length;
                              });
                            },
                          ),
                          title: Text(student["StudentName"]),
                          subtitle: Text(
                            "Father: ${student["FatherName"]}\nRoll: ${student["RollNo"]}",
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // SEND BUTTON (with loader)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                      ),
                      onPressed: isSending ? null : sendAlert,
                      child: isSending
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Send Alert",
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
