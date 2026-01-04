import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SchoolInfoPage extends StatefulWidget {
  @override
  State<SchoolInfoPage> createState() => _SchoolInfoPageState();
}

class _SchoolInfoPageState extends State<SchoolInfoPage> {
  String schoolName = "My School";
  String schoolLogo = "";
  String qrCode = "";
  Map<String, String> schoolDetails = {};
  bool isLoading = true;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    fetchSchoolInfo();
  }

  Future<void> fetchSchoolInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('https://rmps.apppro.in/api/school'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        schoolLogo = data['SchoolLogo'] ?? '';
        qrCode = data['QRCode'] ?? '';
        schoolName = data['SchoolName'] ?? 'My School';
        schoolDetails = {
          "Email": data['SchEmail'] ?? '',
          "Website": data['Website'] ?? '',
          "Address": data['Address'] ?? '',
          "Principal": data["PrincipalName"] ?? '',
          "Contact": data["ContactNo"].toString(),
        };
        isLoading = false;
      });
    } else {
      print("❌ School info fetch failed: ${response.statusCode}");
      setState(() => isLoading = false);
    }
  }

  /// ✅ Downloads the QR Code safely without needing storage permissions
  Future<void> downloadQrCode() async {
    if (qrCode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("QR code not available")));
      return;
    }

    try {
      setState(() => isDownloading = true);
      final response = await http.get(Uri.parse(qrCode));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final directory = await getApplicationDocumentsDirectory();
        final filePath =
            '${directory.path}/School_QR_${DateTime.now().millisecondsSinceEpoch}.png';
        print("📁 Saved Path: $filePath");
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        setState(() => isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ QR Code saved to Documents folder")),
        );
      } else {
        throw Exception("Download failed");
      }
    } catch (e) {
      setState(() => isDownloading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Failed to download QR Code")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "School Information",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        leading: BackButton(color: Colors.white),
      ),
      backgroundColor: Colors.deepPurple[50],
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Card(
                margin: EdgeInsets.all(16),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // 🏫 Logo & Name
                      Column(
                        children: [
                          schoolLogo.isNotEmpty
                              ? Image.network(schoolLogo, height: 100)
                              : Image.asset(
                                  "assets/images/logo.png",
                                  height: 100,
                                ),
                          SizedBox(height: 10),
                          Text(
                            schoolName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // 🟦 Section Title
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border(
                            left: BorderSide(color: Colors.blue, width: 4),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            "School Details",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // 📝 School Info List
                      ...schoolDetails.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  entry.key,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(flex: 5, child: Text(entry.value)),
                            ],
                          ),
                        ),
                      ),

                      // 🧾 QR Code Section
                      if (qrCode.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Divider(),
                        Text(
                          "Payment QR Code",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Image.network(qrCode, height: 150, width: 150),
                        const SizedBox(height: 12),

                        // ⬇️ Download Button
                        ElevatedButton.icon(
                          onPressed: isDownloading ? null : downloadQrCode,
                          icon: isDownloading
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(Icons.download, color: Colors.white),

                          label: Text(
                            isDownloading
                                ? "Downloading..."
                                : "Download QR Code",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            textStyle: TextStyle(color: Colors.white),
                            backgroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
