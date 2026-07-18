import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/user_service.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List conversations = [];

  @override
  void initState() {
    super.initState();
    loadConversations();
  }

  Future<void> loadConversations() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/get_conversations.php"
          "?user_id=${UserService.id}",
        ),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        setState(() {
          conversations = data["conversations"];
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mesajlar"), centerTitle: true),

      body: conversations.isEmpty
          ? const Center(child: Text("Henüz mesaj bulunmuyor."))
          : ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final item = conversations[index];

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),

                  title: Text(item["username"].toString()),

                  subtitle: Text(
                    item["last_message"].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  trailing: Text(
                    item["created_at"].toString().substring(11, 16),
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          receiverId: int.parse(item["user_id"].toString()),
                          receiverName: item["username"].toString(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
