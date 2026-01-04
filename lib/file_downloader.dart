import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> downloadPdf(BuildContext context, String url, String fileName) async {
  try {
    // Request storage permission
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission is required")),
      );
      return;
    }

    // Check and correct URL
    if (!url.startsWith('http')) {
      url = 'https://rmps.apppro.in/$url';
    }

    // Download the file
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to download file');
    }

    // Save to Downloads folder (Android only)
   final downloadsDir = await getExternalStorageDirectory(); // App-private folder

    final filePath = '${downloadsDir?.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Downloaded to $filePath")),
    );

    await OpenFile.open(filePath);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}
