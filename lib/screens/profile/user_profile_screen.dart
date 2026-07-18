import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/user_service.dart';
import '../chat/chat_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;
  final String username;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool loading = true;
  bool following = false;

  int followers = 0;
  int totalProducts = 0;

  Map user = {};

  List products = [];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final profile = await http.get(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/get_user_profile.php?user_id=${widget.userId}",
        ),
      );

      final follow = await http.get(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/check_follow.php?follower_id=${UserService.id}&following_id=${widget.userId}",
        ),
      );

      final followerCount = await http.get(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/get_followers.php?user_id=${widget.userId}",
        ),
      );

      final productResponse = await http.get(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/get_user_products.php?user_id=${widget.userId}",
        ),
      );

      final profileData = jsonDecode(profile.body);
      final followData = jsonDecode(follow.body);
      final countData = jsonDecode(followerCount.body);
      final productData = jsonDecode(productResponse.body);

      if (mounted) {
        setState(() {
          loading = false;

          if (profileData["success"] == true) {
            user = profileData["user"];
            totalProducts =
                int.tryParse(profileData["product_count"].toString()) ?? 0;
          }

          if (productData["success"] == true) {
            products = productData["products"];
          }

          following = followData["following"] == true;
          followers = int.tryParse(countData["count"].toString()) ?? 0;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> toggleFollow() async {
    final response = await http.post(
      Uri.parse("https://lifeos.cadinindiyari.com/api/toggle_follow.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "follower_id": UserService.id,
        "following_id": widget.userId,
      }),
    );

    final data = jsonDecode(response.body);

    if (data["success"] == true) {
      loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Satıcı Profili"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 55),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                user["username"]?.toString() ?? "",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Center(
              child: Text(
                user["fullname"]?.toString() ?? "",
                style: const TextStyle(color: Colors.grey),
              ),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      followers.toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text("Takipçi"),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      totalProducts.toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text("İlan"),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            if (widget.userId != UserService.id)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: toggleFollow,
                  icon: Icon(
                    following ? Icons.person_remove : Icons.person_add,
                  ),
                  label: Text(following ? "Takibi Bırak" : "Takip Et"),
                ),
              ),

            if (widget.userId != UserService.id) const SizedBox(height: 15),

            if (widget.userId != UserService.id)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat),
                  label: const Text("Mesaj Gönder"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          receiverId: widget.userId,
                          receiverName: widget.username,
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 35),

            const Text(
              "Diğer İlanları",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading:
                        product["image"] != null &&
                            product["image"].toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product["image"].toString(),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.image),

                    title: Text(product["title"].toString()),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product["description"].toString()),
                        const SizedBox(height: 4),
                        Text(
                          "${product["price"]} Pi",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
