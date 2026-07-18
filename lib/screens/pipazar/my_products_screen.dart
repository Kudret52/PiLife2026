import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/user_service.dart';
import 'product_detail_screen.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  List products = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/get_my_products.php?user_id=${UserService.id}",
        ),
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        setState(() {
          loading = false;

          if (data["success"] == true) {
            products = data["products"];
          }
        });
      }
    } catch (e) {
      debugPrint(e.toString());

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("İlanlarım"), centerTitle: true),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? const Center(child: Text("Henüz ilan eklemediniz."))
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final item = products[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(item: item),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item["image"] != null &&
                              item["image"].toString().isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item["image"].toString(),
                                width: double.infinity,
                                height: 220,
                                fit: BoxFit.cover,
                              ),
                            ),

                          const SizedBox(height: 10),

                          Text(
                            item["title"].toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(item["description"].toString()),

                          const SizedBox(height: 8),

                          Text(
                            "${item["price"]} Pi",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
