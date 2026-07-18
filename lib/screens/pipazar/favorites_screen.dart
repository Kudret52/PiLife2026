import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/user_service.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List favorites = [];

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/get_favorites.php"
          "?user_id=${UserService.id}",
        ),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        setState(() {
          favorites = data["favorites"];
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> removeFavorite(int productId) async {
    try {
      final response = await http.post(
        Uri.parse("https://lifeos.cadinindiyari.com/api/toggle_favorite.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": UserService.id, "product_id": productId}),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        loadFavorites();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favorilerim"), centerTitle: true),

      body: favorites.isEmpty
          ? const Center(child: Text("Henüz favori ürününüz bulunmuyor."))
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading:
                        item["image"] != null &&
                            item["image"].toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              item["image"].toString(),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.image),

                    title: Text(item["title"].toString()),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${item["price"]} Pi"),
                        Text("@${item["username"]}"),
                      ],
                    ),

                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () {
                        removeFavorite(int.parse(item["id"].toString()));
                      },
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(item: item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
