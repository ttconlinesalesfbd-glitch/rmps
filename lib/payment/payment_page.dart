import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final String apiUrl = 'https://rmps.apppro.in/api/student/payment';
  List<dynamic> payments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPayments();
  }

  Future<void> fetchPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    print("📥 Payment API Response: ${response.body}");

    if (response.statusCode == 200) {
      setState(() {
        payments = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        payments = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load payment records")),
      );
    }
  }



Future<void> downloadReceipt(dynamic paymentId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('https://rmps.apppro.in/api/student/receipt'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: {'payment_id': paymentId.toString()},
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == true) {
      final url = data['url'];
      final filename = url.split('/').last;

      await Permission.storage.request();

      final dir = await getApplicationDocumentsDirectory(); // safer directory
      final filePath = '${dir.path}/$filename';

      final pdfResponse = await http.get(Uri.parse(url));
      final file = File(filePath);
      await file.writeAsBytes(pdfResponse.bodyBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Receipt downloaded: $filename')),
      );

      await OpenFile.open(filePath);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Download failed')),
      );
    }
  } catch (e) {
    print("❌ Error downloading receipt: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error downloading receipt')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Payments", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : ListView.builder(
              itemCount: payments.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final payment = payments[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 210,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: RotatedBox(
                          quarterTurns: -1,
                          child: Text(
                            'Receipt No.\n${payment['RefNo']}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "📅 ${payment['Date']}",
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDetailRow(
                                    "Total Discount",
                                    "${payment['Discount']}",
                                  ),
                                  _buildDetailRow(
                                    "Penalty",
                                    "${payment['Penalty']}",
                                  ),
                                  _buildDetailRow(
                                    "Total Paid",
                                    "${payment['Paid']}",
                                  ),
                                  _buildDetailRow(
                                    "Total Balance",
                                    "${payment['Balance']}",
                                  ),
                                  _buildDetailRow(
                                    "Payment Mode",
                                    "${payment['PayMode']}",
                                  ),
                                  _buildDetailRow(
                                    "Remark",
                                    payment['Remark'] ?? '-',
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.download,
                                  color: Colors.deepPurple,
                                ),
                                onPressed: () {
                                  downloadReceipt(payment['id']);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text("$title :")),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
