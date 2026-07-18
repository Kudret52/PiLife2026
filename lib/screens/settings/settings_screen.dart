import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
