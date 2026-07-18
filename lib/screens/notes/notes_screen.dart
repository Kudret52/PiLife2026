import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/user_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController noteController = TextEditingController();

  List notes = [];

  static const String baseUrl = "https://lifeos.cadinindiyari.com/api";

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get_notes.php?user_id=${UserService.id}"),
      );

      setState(() {
        notes = jsonDecode(response.body);
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> addNote() async {
    if (noteController.text.trim().isEmpty) return;

    try {
      await http.post(
        Uri.parse("$baseUrl/create_note.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": UserService.id,
          "title": noteController.text.trim(),
        }),
      );

      noteController.clear();

      loadNotes();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/delete_note.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id}),
      );

      loadNotes();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notlar"), centerTitle: true),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),

            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: noteController,
                    onSubmitted: (_) => addNote(),
                    decoration: const InputDecoration(
                      hintText: "Yeni not yaz...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: addNote,
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: notes.isEmpty
                ? const Center(
                    child: Text(
                      "Henüz not eklenmedi.",
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.note),

                          title: Text(notes[index]["title"]),

                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteNote(notes[index]["id"]),
                          ),
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
