import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:raj_modern_public_school/changePasswordPage.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:raj_modern_public_school/change_password_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String studentName = "";
  String rollNo = "";
  String className = "";
  String section = "";
  String contact = "";
  String address = "";
  String fatherName = "";
  String motherName = "";
  String dob = "";
  String bloodGroup = "";
  String category = "-";
  String caste = '';
  String religion = '';
  String studentPhoto = "";
  String gender = '';
  String adDate = '';
  String LedNo = '';
  bool isloading = true;

  @override
  void initState() {
    super.initState();
    loadLocalData();
    fetchProfileFromApi();
  }

  Future<void> loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      studentName = prefs.getString('student_name') ?? '';
      className = prefs.getString('class_name') ?? '';
      studentPhoto = prefs.getString('student_photo') ?? '';
      section = prefs.getString('section') ?? '';
    });
  }

  Future<void> fetchProfileFromApi() async {
    try {
      final response = await ApiService.post('/student/profile');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("📦 API Profile Data: $data");
        print("📦 Full API Response Body: ${response.body}");

        final prefs = await SharedPreferences.getInstance();
        // Save data for future access
        await prefs.setString('roll_no', data['RollNo'].toString());
        // await prefs.setString('section', data['section'] ?? '');
        await prefs.setString('mobile_no', data['MobileNo'].toString());
        await prefs.setString('father_name', data['FatherName'] ?? '');
        await prefs.setString('mother_name', data['MotherName'] ?? '');
        await prefs.setString('dob', data['DOB'] ?? '');
        await prefs.setString('blood_group', data['BloodGroup'] ?? '');
        await prefs.setString('aadhaar', data['LedgerNo'] ?? '');
        await prefs.setString('gender', data['Gender'] ?? '');
        await prefs.setString('address', data['Address'] ?? '');

        // Update UI
        setState(() {
          rollNo = data['RollNo'].toString();
          section = prefs.getString('section') ?? '';
          contact = data['MobileNo'].toString();
          fatherName = data['FatherName'] ?? '';
          motherName = data['MotherName'] ?? '';
          dob = data['DOB'] ?? '';
          gender = data['Gender'] ?? '';
          bloodGroup = data['BloodGroup'] ?? '';
          caste = data['Caste'] ?? '';
          religion = data['Religion'] ?? '';
          category = data['Category'] ?? '';
          address = data['Address'] ?? '';
          LedNo = data['LedgerNo'] ?? '';
          adDate = data['AdmissionDate'] ?? '';
        });
        isloading = false;
      } else {
        print('❌ Profile fetch failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Student Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isloading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundImage: NetworkImage(
                              studentPhoto.isNotEmpty
                                  ? studentPhoto
                                  : 'https/images/logo.png',
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  studentName,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),

                                Text("Class: $className - $section"),
                                Text("Roll No: $rollNo"),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 30, thickness: 1),
                      buildInfoRow(
                        Icons.people,
                        "Father's Name",
                        "$fatherName ",
                      ),
                      buildInfoRow(
                        Icons.people,
                        "Mother's Name",
                        " $motherName",
                      ),
                      buildInfoRow(Icons.person, "Gender", gender),
                      buildInfoRow(Icons.phone, "Contact", contact),
                      buildInfoRow(Icons.cake, "Date Of Birth", dob),
                      buildInfoRow(
                        Icons.calendar_today,
                        "Addmission Date",
                        '$adDate',
                      ),
                      buildInfoRow(
                        Icons.card_membership,
                        "Ledger No.",
                        '$LedNo',
                      ),
                      buildInfoRow(
                        Icons.self_improvement,
                        "Religion",
                        '$religion',
                      ),
                      buildInfoRow(Icons.badge, "Category", '$category'),
                      buildInfoRow(Icons.label_important, "Caste", '$caste'),
                      buildInfoRow(
                        Icons.water_drop,
                        "Blood Group",
                        "$bloodGroup",
                      ),
                      buildInfoRow(Icons.location_on, "Address", address),

                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordPage(),
                            ),
                          );
                        },
                        icon: Icon(Icons.lock, color: Colors.white),
                        label: Text(
                          "Change Password",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          SizedBox(width: 10),
          Text("$title: ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
