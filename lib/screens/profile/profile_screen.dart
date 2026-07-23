import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/user_service.dart';
import '../login/login_screen.dart';
import '../../widgets/badge_chips.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loading = true;

  int followers = 0;
  int following = 0;
  int totalProducts = 0;
  List badges = [];
  double? rating;
  int ratingCount = 0;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final profile = await http.get(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/get_user_profile.php?user_id=${UserService.id}",
        ),
      );

      final badgesResponse = await http.get(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/get_user_badges.php?user_id=${UserService.id}",
        ),
      );

      final profileData = jsonDecode(profile.body);
      final badgesData = jsonDecode(badgesResponse.body);

      if (!mounted) return;

      setState(() {
        loading = false;

        if (profileData["success"] == true) {
          totalProducts =
              int.tryParse(profileData["product_count"].toString()) ?? 0;
          followers = int.tryParse(profileData["followers"].toString()) ?? 0;
          following = int.tryParse(profileData["following"].toString()) ?? 0;
          rating = profileData["rating"] != null
              ? double.tryParse(profileData["rating"].toString())
              : null;
          ratingCount =
              int.tryParse(profileData["rating_count"].toString()) ?? 0;
        }

        if (badgesData["success"] == true) {
          badges = badgesData["badges"] ?? [];
        }
      });
    } catch (e) {
      debugPrint("loadProfile hata: $e");
      if (mounted) setState(() => loading = false);
    }
  }

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

  Widget statKutusu(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil"), centerTitle: true),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 20),

            const CircleAvatar(radius: 55, child: Icon(Icons.person, size: 55)),

            const SizedBox(height: 15),

            Text(
              UserService.fullname,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            Text(
              "@${UserService.username}",
              style: const TextStyle(color: Colors.grey),
            ),

            if (!loading && rating != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    "${rating!.toStringAsFixed(1)} ($ratingCount değerlendirme)",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],

            if (!loading && badges.isNotEmpty) ...[
              const SizedBox(height: 12),
              BadgeChips(badges: badges),
            ],

            const SizedBox(height: 20),

            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: CircularProgressIndicator(),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  statKutusu(followers.toString(), "Takipçi"),
                  statKutusu(following.toString(), "Takip"),
                  statKutusu(totalProducts.toString(), "İlan"),
                ],
              ),

            const SizedBox(height: 25),

            bilgiKutusu("Ad Soyad", UserService.fullname, Icons.badge),

            bilgiKutusu(
              "Kullanıcı Adı",
              UserService.username,
              Icons.alternate_email,
            ),

            bilgiKutusu("E-Posta", UserService.email, Icons.email),

            const SizedBox(height: 20),

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
