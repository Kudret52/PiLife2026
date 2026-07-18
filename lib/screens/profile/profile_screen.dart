import 'package:flutter/material.dart';

import '../../services/user_service.dart';
import '../login/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> logout(BuildContext context) async {
    await UserService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget bilgiKutusu(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(
          value.isEmpty ? "-" : value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil"), centerTitle: true),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 20),

            const CircleAvatar(radius: 55, child: Icon(Icons.person, size: 55)),

            const SizedBox(height: 25),

            bilgiKutusu("Ad Soyad", UserService.fullname, Icons.badge),

            bilgiKutusu(
              "Kullanıcı Adı",
              UserService.username,
              Icons.alternate_email,
            ),

            bilgiKutusu("E-Posta", UserService.email, Icons.email),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => logout(context),
                icon: const Icon(Icons.logout),
                label: const Text("Çıkış Yap", style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
