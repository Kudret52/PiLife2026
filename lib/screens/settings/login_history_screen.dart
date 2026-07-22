import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/user_service.dart';

class LoginHistoryScreen extends StatefulWidget {
  const LoginHistoryScreen({super.key});

  @override
  State<LoginHistoryScreen> createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends State<LoginHistoryScreen> {
  static const Color primaryColor = Color(0xFF5B2D90);

  bool loading = true;
  List history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/get_login_history.php"
          "?user_id=${UserService.id}",
        ),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        loading = false;
        if (data["success"] == true) {
          history = data["history"] ?? [];
        }
      });
    } catch (e) {
      debugPrint("loadHistory hata: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  String formatDate(String raw) {
    try {
      final date = DateTime.parse(raw);
      return "${date.day.toString().padLeft(2, '0')}."
          "${date.month.toString().padLeft(2, '0')}."
          "${date.year} "
          "${date.hour.toString().padLeft(2, '0')}:"
          "${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Giriş Geçmişi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
          ? const Center(child: Text("Giriş geçmişi bulunamadı."))
          : RefreshIndicator(
              onRefresh: loadHistory,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFF4AF2C),
                        child: Icon(Icons.login_rounded, color: primaryColor),
                      ),
                      title: Text(
                        (item["device_info"] ?? "").toString().isNotEmpty
                            ? item["device_info"].toString()
                            : "Bilinmeyen cihaz",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${formatDate(item["created_at"].toString())}"
                        "${(item["ip_address"] ?? "").toString().isNotEmpty ? " • ${item["ip_address"]}" : ""}",
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
