import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherChatScreen extends StatefulWidget {
  final int studentId;
  final String studentName;
  final String studentPhoto;

  const TeacherChatScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
    required this.studentPhoto,
  }) : super(key: key);

  @override
  State<TeacherChatScreen> createState() => _TeacherChatScreenState();
}

class _TeacherChatScreenState extends State<TeacherChatScreen> {
  List<dynamic> messages = [];
  bool _isLoading = true;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> fetchMessages({bool autoRefresh = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception("No token found in SharedPreferences");

      final response = await http.post(
        Uri.parse("https://rmps.apppro.in/api/teacher/messages"),
        headers: {"Authorization": "Bearer $token"},
        body: {"StudentId": widget.studentId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          // 🔹 Update only if new messages are different
          final newMessages = data['messages'];
          if (!listEquals(messages, newMessages)) {
            setState(() {
              messages = newMessages;
              _isLoading = false;
            });

            // 🔹 Scroll only if not auto-refresh
            if (!autoRefresh) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(
                    _scrollController.position.maxScrollExtent,
                  );
                }
              });
            }
          }
        }
      } else {
        throw Exception("Failed to load messages");
      }
    } catch (e) {
      print("❌ Error loading messages: $e");
      if (!autoRefresh) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception("No token found in SharedPreferences");

      final response = await http.post(
        Uri.parse("https://rmps.apppro.in/api/teacher/message/send"),
        headers: {"Authorization": "Bearer $token"},
        body: {"receiver_id": widget.studentId.toString(), "message": text},
      );

      if (response.statusCode == 200) {
        setState(() {
          messages.add({
            "sender_type": "teacher",
            "message": text,
            "created_at": DateTime.now().toString(),
          });
        });
        _messageController.clear();

        // Smooth scroll to bottom
        Future.delayed(const Duration(milliseconds: 200), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      print("❌ Error sending message: $e");
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(widget.studentPhoto),
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(width: 10),
            Text(
              widget.studentName,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => fetchMessages(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? const Center(child: Text("No messages yet"))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isTeacher = msg['sender_type'] == "teacher";

                      return Align(
                        alignment: isTeacher
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: isTeacher
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isTeacher
                                    ? Colors.deepPurple.shade400
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: Radius.circular(
                                    isTeacher ? 12 : 0,
                                  ),
                                  bottomRight: Radius.circular(
                                    isTeacher ? 0 : 12,
                                  ),
                                ),
                              ),
                              child: Text(
                                msg['message'] ?? '',
                                style: TextStyle(
                                  color: isTeacher
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (msg['created_at'] != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 8,
                                  right: 8,
                                  bottom: 4,
                                ),
                                child: Text(
                                  DateFormat('dd MMM, hh:mm a').format(
                                    DateTime.parse(msg['created_at']).toLocal(),
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.deepPurple,
              radius: 22,
              child: _isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: sendMessage,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
