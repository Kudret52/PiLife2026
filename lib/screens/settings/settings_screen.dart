import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/user_service.dart';
import 'login_history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool autoLoginEnabled = true;

  static const Color primaryColor = Color(0xFF5B2D90);
  static const Color accentColor = Color(0xFFF4AF2C);
  static const Color backgroundColor = Color(0xFFF7F5FC);

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      notificationsEnabled = prefs.getBool("notifications_enabled") ?? true;

      autoLoginEnabled = prefs.getBool("auto_login_enabled") ?? true;
    });
  }

  Future<void> saveNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool("notifications_enabled", value);

    setState(() {
      notificationsEnabled = value;
    });
  }

  Future<void> saveAutoLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool("auto_login_enabled", value);

    setState(() {
      autoLoginEnabled = value;
    });
  }

  void showAbout() {
    showAboutDialog(
      context: context,
      applicationName: "PiLife",
      applicationVersion: "1.0.0",
      applicationLegalese: "© 2026 PiLife",
    );
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("https://lifeos.cadinindiyari.com/api/change_password.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": UserService.id,
          "current_password": currentPassword,
          "new_password": newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data["message"]?.toString() ?? "Bilinmeyen hata"),
        ),
      );

      if (data["success"] == true) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  void showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Şifre Değiştir"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Mevcut Şifre"),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: newController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Yeni Şifre"),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Yeni Şifre (Tekrar)",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                if (newController.text != confirmController.text) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text("Yeni şifreler eşleşmiyor.")),
                  );
                  return;
                }

                changePassword(currentController.text, newController.text);
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  Widget ayarKart({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accentColor,
          child: Icon(icon, color: primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "PiLife Ayarlar",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView(
        children: [
          const SizedBox(height: 10),

          ayarKart(
            icon: Icons.notifications,
            title: "Bildirimler",
            subtitle: "Uygulama bildirimlerini al",
            trailing: Switch(
              value: notificationsEnabled,
              activeThumbColor: accentColor,
              onChanged: saveNotifications,
            ),
          ),

          ayarKart(
            icon: Icons.login,
            title: "Otomatik Giriş",
            subtitle: "Uygulama açıldığında otomatik giriş yap",
            trailing: Switch(
              value: autoLoginEnabled,
              activeThumbColor: accentColor,
              onChanged: saveAutoLogin,
            ),
          ),

          Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: accentColor,
                child: Icon(Icons.lock, color: primaryColor),
              ),
              title: const Text(
                "Şifre Değiştir",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Hesap şifrenizi güncelleyin"),
              trailing: const Icon(Icons.chevron_right),
              onTap: showChangePasswordDialog,
            ),
          ),

          Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: accentColor,
                child: Icon(Icons.history, color: primaryColor),
              ),
              title: const Text(
                "Giriş Geçmişi",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Hesabınıza yapılan girişleri görün"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginHistoryScreen()),
                );
              },
            ),
          ),

          Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: const ListTile(
              leading: CircleAvatar(
                backgroundColor: accentColor,
                child: Icon(Icons.info, color: primaryColor),
              ),
              title: Text(
                "Uygulama Sürümü",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("1.0.0"),
            ),
          ),

          Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: accentColor,
                child: Icon(Icons.description, color: primaryColor),
              ),
              title: const Text(
                "Hakkında",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("PiLife hakkında bilgi"),
              onTap: showAbout,
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
