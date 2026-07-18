import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/user_service.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final TextEditingController taskController = TextEditingController();

  List tasks = [];

  static const String baseUrl = "https://lifeos.cadinindiyari.com/api";

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/get_tasks.php?user_id=${UserService.id}"),
      );

      setState(() {
        tasks = jsonDecode(response.body);
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> addTask() async {
    if (taskController.text.trim().isEmpty) return;

    try {
      await http.post(
        Uri.parse("$baseUrl/create_task.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": UserService.id,
          "title": taskController.text.trim(),
        }),
      );

      taskController.clear();

      loadTasks();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/delete_task.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id}),
      );

      loadTasks();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Görevler"), centerTitle: true),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),

            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: taskController,
                    decoration: const InputDecoration(
                      hintText: "Yeni görev ekle...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => addTask(),
                  ),
                ),

                const SizedBox(width: 10),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: addTask,
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: tasks.isEmpty
                ? const Center(
                    child: Text(
                      "Henüz görev eklenmedi.",
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 5,
                        ),

                        child: ListTile(
                          title: Text(tasks[index]["title"]),

                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteTask(tasks[index]["id"]),
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
