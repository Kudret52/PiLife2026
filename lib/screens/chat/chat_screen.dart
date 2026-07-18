import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/user_service.dart';

class ChatScreen extends StatefulWidget {
  final int receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  List messages = [];

  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();

    loadMessages();

    refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      loadMessages();
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void scrollToBottom() {
    if (!scrollController.hasClients) return;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> loadMessages() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/get_messages.php"
          "?user1=${UserService.id}&user2=${widget.receiverId}",
        ),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        final oldCount = messages.length;

        setState(() {
          messages = data["messages"];
        });

        if (messages.length != oldCount) {
          scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint("loadMessages hata: $e");
    }
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("https://lifeos.cadinindiyari.com/api/send_message.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender_id": UserService.id,
          "receiver_id": widget.receiverId,
          "message": messageController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        messageController.clear();

        await loadMessages();

        scrollToBottom();
      }
    } catch (e) {
      debugPrint("sendMessage hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName), centerTitle: true),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final item = messages[index];

                final isMe =
                    item["sender_id"].toString() == UserService.id.toString();

                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 280),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF5B2D90)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      item["message"].toString(),
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: "Mesaj yaz...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) {
                      sendMessage();
                    },
                  ),
                ),

                const SizedBox(width: 10),

                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
