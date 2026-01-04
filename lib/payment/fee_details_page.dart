import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FeeDetailsPage extends StatefulWidget {
  const FeeDetailsPage({super.key});

  @override
  State<FeeDetailsPage> createState() => _FeeDetailsPageState();
}

class _FeeDetailsPageState extends State<FeeDetailsPage> {
  final String apiUrl = 'https://rmps.apppro.in/api/student/fee';

  final List<String> months = [
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
    'January',
    'February',
    'March',
  ];
  final List<String> monthApiKeys = [
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
    'Jan',
    'Feb',
    'Mar',
  ];

  int selectedMonthIndex = 0;
  bool isLoading = true;
  List<dynamic> feeData = [];

  @override
  void initState() {
    super.initState();
    fetchFeeData(monthApiKeys[selectedMonthIndex]);
  }

  Future<void> fetchFeeData(String monthKey) async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'Month': monthKey}),
    );

    print("📥 Fee API Response (${monthKey}): ${response.body}");

    if (response.statusCode == 200) {
      setState(() {
        feeData = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        feeData = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch fee details")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xfff7f2f9),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text("Fee Details", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: months.length,
              itemBuilder: (context, index) {
                final isSelected = index == selectedMonthIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(months[index]),
                    selected: isSelected,
                    checkmarkColor: Colors.white,
                    selectedColor: Colors.deepPurple,

                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                    onSelected: (selected) {
                      setState(() => selectedMonthIndex = index);
                      fetchFeeData(monthApiKeys[index]);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.deepPurple),
                  )
                : feeData.isEmpty
                ? const Center(child: Text("No fee records for this month"))
                : ListView.builder(
                    itemCount: feeData.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final record = feeData[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.credit_card,
                            color: Colors.deepPurple,
                          ),
                          title: Text("₹${record['Fee']}"),
                          subtitle: Text("Mode: ${record['FeeName']}"),
                          trailing: Text(record['Date']),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
