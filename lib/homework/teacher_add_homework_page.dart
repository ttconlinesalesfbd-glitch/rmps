import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class TeacherAddHomeworkPage extends StatefulWidget {
  final Map<String, dynamic>? homeworkToEdit;
  const TeacherAddHomeworkPage({super.key, this.homeworkToEdit});

  @override
  State<TeacherAddHomeworkPage> createState() => _TeacherAddHomeworkPageState();
}

class _TeacherAddHomeworkPageState extends State<TeacherAddHomeworkPage> {
  List classes = [];
  List sections = [];
  int? selectedClassId;
  int? selectedSectionId;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? assignDate;
  DateTime? submissionDate;
  File? selectedFile;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();
    assignDate = today;
    submissionDate = today;
    if (widget.homeworkToEdit != null) {
      // Homework details fetch karne se pehle classes aur sections ko await karein
      _loadEditData();
    } else {
      // Naya homework add karne ke liye
      fetchClasses();
    }
  }

  Future<void> _loadEditData() async {
    setState(() => isLoading = true);
    await fetchClasses();
    await fetchHomeworkDetails(widget.homeworkToEdit!['id']);
    setState(() => isLoading = false);
  }

  // --- Utility Functions ---

  Future<void> fetchClassesAndSections() async {
    setState(() => isLoading = true);
    await fetchClasses();
    if (selectedClassId != null) {
      await fetchSections(selectedClassId!);
    }
    setState(() => isLoading = false);
  }

  Future<void> fetchClasses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('https://rmps.apppro.in/api/get_class'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        classes = jsonDecode(response.body);
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch classes")),
        );
      }
    }
  }

  Future<void> fetchSections(int classId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('https://rmps.apppro.in/api/get_section'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'ClassId': classId}),
    );

    if (response.statusCode == 200) {
      setState(() {
        sections = jsonDecode(response.body);
        selectedSectionId = null; // Reset section on class change
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to fetch sections")),
        );
      }
    }
  }

  // --- New `fetchHomeworkDetails` Function ---
  Future<void> fetchHomeworkDetails(int homeworkId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('https://rmps.apppro.in/api/teacher/homework/edit'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'HomeworkId': homeworkId}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      // Title aur Description ko set karein
      setState(() {
        _titleController.text = data['HomeworkTitle'] ?? '';
        _descriptionController.text = data['Remark'] ?? '';
        assignDate = DateTime.tryParse(data['WorkDate'] ?? '');
        submissionDate = DateTime.tryParse(data['SubmissionDate'] ?? '');
      });

      // Class aur Section ID ko check aur set karein
      final classId = int.tryParse(data['Class'] ?? '');
      final sectionId = int.tryParse(data['Section'] ?? '');

      if (classId != null && classes.any((c) => c['id'] == classId)) {
        setState(() {
          selectedClassId = classId;
        });
        // Sections fetch karein
        await fetchSections(selectedClassId!);
        if (sectionId != null && sections.any((s) => s['id'] == sectionId)) {
          setState(() {
            selectedSectionId = sectionId;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load homework details')),
      );
    }
  }
  // --- Updated `submitHomework` Function ---

  Future<void> submitHomework() async {
    // ... (rest of the validation code is the same)
    if (selectedClassId == null ||
        selectedSectionId == null ||
        assignDate == null ||
        submissionDate == null ||
        _titleController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final isEditMode = widget.homeworkToEdit != null;
    final apiUrl = isEditMode
        ? 'https://rmps.apppro.in/api/teacher/homework/update'
        : 'https://rmps.apppro.in/api/teacher/homework/store';

    final request = http.MultipartRequest('POST', Uri.parse(apiUrl))
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['Class'] = selectedClassId.toString()
      ..fields['Section'] = selectedSectionId.toString()
      ..fields['Title'] = _titleController.text
      ..fields['Description'] = _descriptionController.text;

    if (isEditMode) {
      request.fields['HomeworkId'] = widget.homeworkToEdit!['id'].toString();
      request.fields['AssignDate'] = DateFormat(
        'yyyy-MM-dd',
      ).format(assignDate!);
      request.fields['SubmissionDate'] = DateFormat(
        'yyyy-MM-dd',
      ).format(submissionDate!);
    } else {
      request.fields['AssignDate'] = DateFormat(
        'yyyy-MM-dd',
      ).format(assignDate!);
      request.fields['SubmissionDate'] = DateFormat(
        'yyyy-MM-dd',
      ).format(submissionDate!);
    }

    if (selectedFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('Attachment', selectedFile!.path),
      );
    }

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final decoded = jsonDecode(respStr);

      setState(() => isLoading = false);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(decoded['message'])));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded['message'] ?? 'Upload failed')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (rest of the build method is the same)
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.homeworkToEdit != null ? "Edit Homework" : "Add Homework",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: "Class"),
                    initialValue: selectedClassId,
                    items: classes.map((cls) {
                      return DropdownMenuItem<int>(
                        value: cls['id'],
                        child: Text(cls['Class']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => selectedClassId = val);
                      if (val != null) fetchSections(val);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: "Section"),
                    initialValue: selectedSectionId,
                    items: sections.map((sec) {
                      return DropdownMenuItem<int>(
                        value: sec['id'],
                        child: Text(sec['SectionName']),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedSectionId = val),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Homework Title",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: "Description"),
                    maxLines: 6,
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Assign Date",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: assignDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              assignDate = picked;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                assignDate != null
                                    ? DateFormat(
                                        'dd-MM-yyyy',
                                      ).format(assignDate!)
                                    : DateFormat(
                                        'dd-MM-yyyy',
                                      ).format(DateTime.now()),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.deepPurple,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Submission Date",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: submissionDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              submissionDate = picked;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                submissionDate != null
                                    ? DateFormat(
                                        'dd-MM-yyyy',
                                      ).format(submissionDate!)
                                    : DateFormat(
                                        'dd-MM-yyyy',
                                      ).format(DateTime.now()),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.deepPurple,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Attachment (Optional)",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 5),
                      selectedFile == null
                          ? ElevatedButton.icon(
                              icon: const Icon(Icons.attach_file),
                              label: const Text("Choose File"),
                              onPressed: pickFile,
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.deepPurple),
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.deepPurple.withOpacity(0.05),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.insert_drive_file,
                                    color: Colors.deepPurple,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedFile!.path.split('/').last,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        selectedFile = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                      ),
                      onPressed: submitHomework,
                      child: Text(
                        widget.homeworkToEdit != null
                            ? "Update Homework"
                            : "Submit Homework",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
