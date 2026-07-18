import 'package:flutter/material.dart';

import '../../services/user_service.dart';
import '../chat/chat_screen.dart';
import '../profile/user_profile_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final dynamic item;

  const ProductDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final bool isOwner =
        item["user_id"].toString() == UserService.id.toString();

    return Scaffold(
      appBar: AppBar(title: Text(item["title"].toString()), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item["image"] != null && item["image"].toString().isNotEmpty)
              Image.network(
                item["image"].toString(),
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item["title"].toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    "${item["price"]} Pi",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Ürün Açıklaması",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    item["description"].toString(),
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 25),

                  const Divider(),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      const CircleAvatar(child: Icon(Icons.person)),

                      const SizedBox(width: 10),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Satıcı",
                            style: TextStyle(color: Colors.grey),
                          ),

                          Text(
                            item["username"].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  if (!isOwner) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.person),
                        label: const Text("Satıcı Profili"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfileScreen(
                                userId: int.parse(item["user_id"].toString()),
                                username: item["username"].toString(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.chat),
                        label: const Text(
                          "Satıcıya Mesaj Gönder",
                          style: TextStyle(fontSize: 18),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                receiverId: int.parse(
                                  item["user_id"].toString(),
                                ),
                                receiverName: item["username"].toString(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
