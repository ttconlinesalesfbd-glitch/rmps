import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentTeacherScreen extends StatefulWidget {
  const PaymentTeacherScreen({super.key});

  @override
  State<PaymentTeacherScreen> createState() => _PaymentTeacherScreenState();
}

class _PaymentTeacherScreenState extends State<PaymentTeacherScreen> {
  final String apiUrl = 'https://rmps.apppro.in/api/teacher/payment';
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
        const SnackBar(content: Text("Failed to load teacher payment records")),
      );
    }
  }

  Color getBackgroundColor(String particular) {
    return particular == "Employee Payment" ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Teacher Payments",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : payments.isEmpty
          ? const Center(child: Text("No payments found."))
          : ListView.builder(
              itemCount: payments.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final payment = payments[index];
                final color = getBackgroundColor(payment['Particular']);

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
                        height: 150,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: RotatedBox(
                          quarterTurns: -1,
                          child: Text(
                            (payment['Particular']?.split(' ').last ?? ''),

                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
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
                                payment['Particular'] == "Employee Salary"
                                    ? "Amount"
                                    : "Received",
                                payment['Particular'] == "Employee Payment"
                                    ? (payment['Paid'] ?? '0')
                                    : (payment['Paid'] ?? '0'),
                              ),

                              _buildDetailRow(
                                "Pay Mode",
                                payment['PayMode'] ?? '-',
                              ),
                              _buildDetailRow(
                                "Remark",
                                payment['Remark'] ?? '-',
                              ),
                            ],
                          ),
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
          SizedBox(width: 120, child: Text("$title :")),
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
