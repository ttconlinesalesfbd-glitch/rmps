import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class ViewHomeworksPage extends StatelessWidget {
  final List<Map<String, dynamic>> homeworks;

  const ViewHomeworksPage({super.key, required this.homeworks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assigned Homeworks", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: homeworks.length,
        itemBuilder: (context, index) {
          final hw = homeworks[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(hw['HomeworkTitle'] ?? 'No Title'),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Assign: ${_formatDate(hw['WorkDate'])}"),
                    Text("Submit: ${_formatDate(hw['SubmissionDate'])}"),
                    Text("Remark: ${hw['Remark'] ?? ''}"),
                  ],
                ),
              ),
              trailing: hw['Attachment'] != null
                  ? IconButton(
                      icon: const Icon(Icons.download, color: Colors.deepPurple),
                      onPressed: () {
                        String fileUrl = hw['Attachment'];
                        String fileName = fileUrl.split('/').last;

                        if (!fileUrl.startsWith('http')) {
                          fileUrl = 'https://rmps.apppro.in/$fileUrl';
                        }

                        downloadFile(context, fileUrl, fileName);
                      },
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> downloadFile(BuildContext context, String fileUrl, String fileName) async {
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission is required")),
        );
        return;
      }
    }

    try {
      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        final dir = await getExternalStorageDirectory();
        final file = File('${dir!.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Downloaded to ${file.path}")),
        );

        await OpenFile.open(file.path);
      } else {
        throw Exception('Download failed with status ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download error: $e")),
      );
    }
  }
}
