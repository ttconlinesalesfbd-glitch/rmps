import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raj_modern_public_school/teacher/complaint_teacher/teacher_add_complaint_page.dart';
import 'package:raj_modern_public_school/teacher/complaint_teacher/teacher_complaint_details.dart';


class TeacherComplaintListPage extends StatefulWidget {
  const TeacherComplaintListPage({super.key});

  @override
  State<TeacherComplaintListPage> createState() =>
      _TeacherComplaintListPageState();
}

class _TeacherComplaintListPageState extends State<TeacherComplaintListPage> {
  final String apiUrl = 'https://rmps.apppro.in/api/teacher/complaint';
  List<dynamic> complaints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    print("🔐 Token: $token");

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      print("🔄 Response: ${response.body}");

      print("📦 Status Code: ${response.statusCode}");
      print("📨 Raw Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print("✅ Decoded JSON: $decoded");

        if (decoded is List) {
          setState(() {
            complaints = decoded;
            isLoading = false;
          });
        } else {
          print("❌ Decoded response is not a list.");
          setState(() {
            complaints = [];
            isLoading = false;
          });
        }
      } else {
        print("❌ Failed to fetch. Status code: ${response.statusCode}");
        setState(() {
          complaints = [];
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load complaints')),
        );
      }
    } catch (e) {
      print("❌ Exception while fetching complaints: $e");
      setState(() {
        complaints = [];
        isLoading = false;
      });
    }
  }

  Color getStatusColor(int status) {
    return status == 1 ? Colors.green : Colors.orange;
  }

  String getStatusText(int status) {
    return status == 1 ? 'Solved' : 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Complaints',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : complaints.isEmpty
          ? const Center(child: Text('No complaints available'))
          : ListView.builder(
              itemCount: complaints.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final complaint = complaints[index];
                final status = complaint['Status'];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherComplaintDetailPage(
                          complaintId: complaint['id'],
                          date: complaint['Date'],
                          description: complaint['Description'],
                          status: status,
                          studentName: complaint['StudentName'],
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${complaint['StudentName'] ?? 'N/A'}",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.date_range,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formatDate(complaint['Date'] ?? ''),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  if (status != 0)
                                    return; // Show popup only if status is Pending

                                  TextEditingController _descController =
                                      TextEditingController();
                                  int selectedStatus = 0;

                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        elevation: 16,
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                        horizontal: 16,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors
                                                        .deepPurple
                                                        .shade100, // Lighter shade for a softer look
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    "Update Complaint",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.deepPurple,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(height: 20),

                                                // Dropdown Field
                                                DropdownButtonFormField<int>(
                                                  initialValue: selectedStatus,
                                                  decoration: InputDecoration(
                                                    labelText: "Change Status",
                                                    prefixIcon: const Icon(
                                                      Icons.sync,
                                                    ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                  items: const [
                                                    DropdownMenuItem(
                                                      value: 0,
                                                      child: Text("Pending"),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 1,
                                                      child: Text("Solved"),
                                                    ),
                                                  ],
                                                  onChanged: (val) {
                                                    selectedStatus = val!;
                                                  },
                                                ),
                                                const SizedBox(height: 16),

                                                // Description Field
                                                TextField(
                                                  controller: _descController,
                                                  maxLines: 3,
                                                  decoration: InputDecoration(
                                                    labelText: "Description",
                                                    hintText:
                                                        "Enter details or reason...",
                                                    prefixIcon: const Icon(
                                                      Icons.description,
                                                    ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 24),

                                                // Buttons
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    OutlinedButton.icon(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                          ),
                                                      icon: const Icon(
                                                        Icons.cancel,
                                                        color: Colors.red,
                                                      ),
                                                      label: const Text(
                                                        "Cancel",
                                                        style: TextStyle(
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                    ElevatedButton.icon(
                                                      onPressed: () async {
                                                        final desc =
                                                            _descController.text
                                                                .trim();
                                                        if (desc.isEmpty)
                                                          return;

                                                        final prefs =
                                                            await SharedPreferences.getInstance();
                                                        final token =
                                                            prefs.getString(
                                                              'token',
                                                            ) ??
                                                            '';

                                                        final response = await http.post(
                                                          Uri.parse(
                                                            "https://rmps.apppro.in/api/teacher/complaint/history/store",
                                                          ),
                                                          headers: {
                                                            'Authorization':
                                                                'Bearer $token',
                                                            'Accept':
                                                                'application/json',
                                                          },
                                                          body: {
                                                            "ComplaintId":
                                                                complaint['id']
                                                                    .toString(),
                                                            "Status":
                                                                selectedStatus
                                                                    .toString(),
                                                            "Description": desc,
                                                          },
                                                        );

                                                        print(
                                                          "🟢 Response: ${response.body}",
                                                        );
                                                        Navigator.pop(context);

                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              "✅ Complaint updated",
                                                            ),
                                                          ),
                                                        );

                                                        fetchComplaints(); // Refresh
                                                      },
                                                      icon: const Icon(
                                                        Icons.save,
                                                      ),
                                                      label: const Text("Save"),
                                                      style: ElevatedButton.styleFrom(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 20,
                                                              vertical: 12,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: getStatusColor(
                                      status,
                                    ).withOpacity(0.1),
                                    border: Border.all(
                                      color: getStatusColor(status),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        status == 0
                                            ? Icons.timelapse
                                            : Icons.check_circle,
                                        size: 16,
                                        color: getStatusColor(status),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        getStatusText(status),
                                        style: TextStyle(
                                          color: getStatusColor(status),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            complaint['Description']?.replaceAll(
                                  r"\r\n",
                                  "\n",
                                ) ??
                                '',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

      /// ✅ Floating Button Added Here
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TeacherAddComplaintPage()),
          );
          if (result == true) {
            fetchComplaints();
            setState(() {});
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

String formatDate(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd-MM-yyyy').format(date);
  } catch (e) {
    return dateStr;
  }
}
