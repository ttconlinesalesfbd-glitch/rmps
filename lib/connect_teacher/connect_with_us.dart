import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ConnectWithUsPage extends StatefulWidget {
  const ConnectWithUsPage({super.key});

  @override
  State<ConnectWithUsPage> createState() => _ConnectWithUsPageState();
}

class _ConnectWithUsPageState extends State<ConnectWithUsPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool isSending = false;
  bool isLoading = true;
  String teacherName = "";
  String teacherPhoto = "";
  int teacherId = 0;
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();

    fetchMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 🟢 FETCH MESSAGES FROM API
  Future<void> fetchMessages({bool autoRefresh = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        print('🔴 No token found in SharedPreferences');
        return;
      }

      print('📡 Fetching messages...');
      print('🔹 API: https://rmps.apppro.in/api/student/messages');
      print('🔹 Headers: {Authorization: Bearer $token}');

      final url = Uri.parse("https://rmps.apppro.in/api/student/messages");
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print('🟢 Response Code: ${response.statusCode}');
      print('🟢 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["status"] == true) {
          teacherId = data["id"] ?? 0;
          teacherName = data["name"] ?? "";
          teacherPhoto = data["photo"] ?? "";

          final newMessages = List<Map<String, dynamic>>.from(
            data["messages"].map((msg) {
              return {
                "sender": msg["sender_type"] == "student" ? "user" : "teacher",
                "text": msg["message"],
                "time": msg["created_at"],
              };
            }),
          );

          if (newMessages.length != messages.length) {
            setState(() {
              messages = newMessages;
            });
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      print("❌ Exception fetching messages: $e");
    } finally {
      if (!autoRefresh) setState(() => isLoading = false);
    }
  }

  // 🟣 SEND MESSAGE API
  Future<void> _handleSendMessage() async {
    if (_messageController.text.trim().isEmpty || teacherId == 0) {
      print('⚠️ Message empty or invalid teacherId');
      return;
    }

    setState(() => isSending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        print('🔴 No token found in SharedPreferences');
        return;
      }

      final message = _messageController.text.trim();
      final url = Uri.parse(
        'https://rmps.apppro.in/api/student/message/send',
      );

      print('📡 Sending message...');
      print('🔹 API: $url');
      print('🔹 Headers: {Authorization: Bearer $token}');
      print('🔹 Body: {receiver_id: $teacherId, message: $message}');

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {'receiver_id': teacherId.toString(), 'message': message},
      );

      print('🟢 Status Code: ${response.statusCode}');
      print('🟢 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true || data['id'] != null) {
          print('✅ Message sent successfully');
          _messageController.clear();
          fetchMessages(); // refresh chat immediately
        } else {
          print('⚠️ Message failed: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        print('🔴 HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception sending message: $e');
    } finally {
      setState(() => isSending = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 🧱 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: teacherPhoto.isNotEmpty
                  ? NetworkImage(teacherPhoto)
                  : const AssetImage("assets/images/default_avatar.png")
                        as ImageProvider,
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacherName.isNotEmpty ? teacherName : "Teacher Name",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Class Teacher",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => fetchMessages(),
          ),
        ],
        titleSpacing: 0,
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey.shade100,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 💬 Messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isUser = msg["sender"] == "user";
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.deepPurple.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: isUser
                                  ? const Radius.circular(12)
                                  : Radius.zero,
                              bottomRight: isUser
                                  ? Radius.zero
                                  : const Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg["text"] ?? "",
                                style: const TextStyle(fontSize: 14),
                              ),

                              Text(
                                DateFormat(
                                  'dd MMM, hh:mm a',
                                ).format(DateTime.parse(msg['time']).toLocal()),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 📝 Input Field
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: "Type your message...",
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: isSending ? null : _handleSendMessage,
                          child: CircleAvatar(
                            backgroundColor: Colors.deepPurple,
                            child: isSending
                                ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
    );
  }
}
