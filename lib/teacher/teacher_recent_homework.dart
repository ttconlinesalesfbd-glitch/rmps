import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:raj_modern_public_school/teacher/teacher_homework_detail_page.dart';
import 'package:raj_modern_public_school/teacher/teacher_homework_page.dart';

class TeacherRecentHomeworks extends StatelessWidget {
  final List<Map<String, dynamic>> homeworks;

  const TeacherRecentHomeworks({super.key, required this.homeworks});

  @override
  Widget build(BuildContext context) {
    final limitedHomeworks = homeworks.take(5).toList();
    print("📦 Received homeworks in widget: $homeworks");

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📝 Recent Homeworks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TeacherHomeworkPage()),
                  );
                },
                child: const Text("View All"),
              ),
            ],
          ),
          limitedHomeworks.isEmpty
              ? const Text("No homeworks available.")
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: limitedHomeworks.length,
                  itemBuilder: (context, index) {
                    final hw = limitedHomeworks[index];
                    return ListTile(
                      leading: const Icon(Icons.book, color: Colors.deepPurple),
                      title: Text(hw['HomeworkTitle'] ?? ''),
                      subtitle: Text(
                        "Submission: ${formatDate(hw['SubmissionDate'])}",
                      ),

                      trailing: hw['Attachment'] != null
                          ? IconButton(
                              icon: const Icon(
                                Icons.download,
                                color: Colors.deepPurple,
                              ),
                              onPressed: () async {
                                final attachment = hw['Attachment'];
                                final fileUrl =
                                    'https://rmps.apppro.in/$attachment';
                                final fileName = fileUrl.split('/').last;

                                await downloadFile(context, fileUrl, fileName);
                              },
                            )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TeacherHomeworkDetailPage(homework: hw),
                          ),
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }

  Future<void> downloadFile(
    BuildContext context,
    String url,
    String fileName,
  ) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // ✅ App private directory (Google-safe)
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("📥 File downloaded")));

        await OpenFile.open(filePath);
      } else {
        throw Exception('Download failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Download failed")));
    }
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "";
    try {
      final parsedDate = DateTime.parse(date);
      return "${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year}";
    } catch (_) {
      return date;
    }
  }
}
