import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/user_service.dart';

import 'product_detail_screen.dart';

class PiPazarScreen extends StatefulWidget {
  const PiPazarScreen({super.key});

  @override
  State<PiPazarScreen> createState() => _PiPazarScreenState();
}

class _PiPazarScreenState extends State<PiPazarScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final searchController = TextEditingController();

  List products = [];
  List filteredProducts = [];
  Set<int> favoriteProducts = {};
  final picker = ImagePicker();
  File? selectedImage;
  @override
  void initState() {
    super.initState();
    loadProducts();
    loadFavorites();
  }

  Future<void> pickImage() async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  Future<String> uploadImage() async {
    if (selectedImage == null) {
      return "";
    }

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/upload_product_image.php",
        ),
      );

      request.files.add(
        await http.MultipartFile.fromPath("image", selectedImage!.path),
      );

      final response = await request.send();

      final responseString = await response.stream.bytesToString();

      debugPrint(responseString);

      final data = jsonDecode(responseString);

      if (data["success"] == true) {
        return data["path"].toString();
      }

      return "";
    } catch (e) {
      debugPrint("uploadImage hata: $e");
      return "";
    }
  }

  Future<void> loadProducts() async {
    try {
      final response = await http.get(
        Uri.parse("https://lifeos.cadinindiyari.com/api/get_products.php"),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        setState(() {
          products = data["products"];
          filteredProducts = List.from(products);
        });
      }
    } catch (e) {
      debugPrint("loadProducts hata: $e");
    }
  }

  Future<void> loadFavorites() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/get_user_favorites.php?user_id=${UserService.id}",
        ),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        setState(() {
          favoriteProducts = Set<int>.from(
            data["favorites"].map((e) => int.parse(e.toString())),
          );
        });
      }
    } catch (e) {
      debugPrint("loadFavorites hata: $e");
    }
  }

  void searchProducts(String value) {
    setState(() {
      filteredProducts = products.where((product) {
        final title = product["title"].toString().toLowerCase();

        final description = product["description"].toString().toLowerCase();

        final query = value.toLowerCase();

        return title.contains(query) || description.contains(query);
      }).toList();
    });
  }

  Future<void> createProduct() async {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }

    try {
      String imagePath = await uploadImage();

      final response = await http.post(
        Uri.parse("https://lifeos.cadinindiyari.com/api/create_product.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": UserService.id,
          "title": titleController.text.trim(),
          "description": descriptionController.text.trim(),
          "price": priceController.text.trim(),
          "image": imagePath,
        }),
      );

      final data = jsonDecode(response.body);

      debugPrint(response.body);

      if (data["success"] == true) {
        if (mounted) {
          Navigator.pop(context);
        }

        titleController.clear();
        descriptionController.clear();
        priceController.clear();

        await loadProducts();

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("İlan oluşturuldu.")));
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"]?.toString() ?? "Bilinmeyen hata"),
          ),
        );
      }
    } catch (e) {
      debugPrint("createProduct hata: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  Future<void> deleteProduct(int productId) async {
    try {
      final response = await http.post(
        Uri.parse("https://lifeos.cadinindiyari.com/api/delete_product.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"product_id": productId, "user_id": UserService.id}),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        await loadProducts();
      }
    } catch (e) {
      debugPrint("deleteProduct hata: $e");
    }
  }

  Future<void> toggleFavorite(int productId) async {
    try {
      final response = await http.post(
        Uri.parse("https://lifeos.cadinindiyari.com/api/toggle_favorite.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": UserService.id, "product_id": productId}),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        setState(() {
          if (data["favorite"] == true) {
            favoriteProducts.add(productId);
          } else {
            favoriteProducts.remove(productId);
          }
        });
      }
    } catch (e) {
      debugPrint("toggleFavorite hata: $e");
    }
  }

  Future<void> updateProduct(
    int productId,
    String title,
    String description,
    String price,
  ) async {
    try {
      String imagePath = "";

      // Yeni resim seçilmişse yükle
      if (selectedImage != null) {
        imagePath = await uploadImage();
      }

      final response = await http.post(
        Uri.parse("https://lifeos.cadinindiyari.com/api/update_product.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "product_id": productId,
          "user_id": UserService.id,
          "title": title,
          "description": description,
          "price": price,
          "image": imagePath,
        }),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        await loadProducts();

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("İlan güncellendi.")));
      }
    } catch (e) {
      debugPrint("updateProduct hata: $e");
    }
  }

  void showEditDialog(dynamic item) {
    final editTitleController = TextEditingController(
      text: item["title"].toString(),
    );

    final editDescriptionController = TextEditingController(
      text: item["description"].toString(),
    );

    final editPriceController = TextEditingController(
      text: item["price"].toString(),
    );

    selectedImage = null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("İlan Düzenle"),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: editTitleController,
                  decoration: const InputDecoration(labelText: "Başlık"),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: editDescriptionController,
                  decoration: const InputDecoration(labelText: "Açıklama"),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: editPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Fiyat"),
                ),

                const SizedBox(height: 15),

                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text("Yeni Resim Seç"),
                ),

                const SizedBox(height: 10),

                if (selectedImage != null)
                  Image.file(selectedImage!, height: 120),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("İptal"),
            ),

            ElevatedButton(
              onPressed: () async {
                await updateProduct(
                  int.parse(item["id"].toString()),
                  editTitleController.text.trim(),
                  editDescriptionController.text.trim(),
                  editPriceController.text.trim(),
                );

                if (mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  void showAddDialog() {
    titleController.clear();
    descriptionController.clear();
    priceController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Yeni İlan"),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Başlık"),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Açıklama"),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Fiyat"),
                ),
                const SizedBox(height: 15),

                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text("Resim Seç"),
                ),

                const SizedBox(height: 10),

                if (selectedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      selectedImage!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("İptal"),
            ),

            ElevatedButton(
              onPressed: () async {
                await createProduct();

                if (!mounted) return;

                Navigator.pop(dialogContext);
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pi Pazar"), centerTitle: true),

      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              onChanged: searchProducts,
              decoration: InputDecoration(
                hintText: "İlan ara...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),

          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(child: Text("İlan bulunamadı."))
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final item = filteredProducts[index];

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
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
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
                                    fontSize: 16,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  "@${item["username"]}",
                                  style: const TextStyle(color: Colors.grey),
                                ),

                                if (item["user_id"].toString() ==
                                    UserService.id.toString())
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.orange,
                                        ),
                                        onPressed: () {
                                          deleteProduct(
                                            int.parse(item["id"].toString()),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                              ],
                            ),
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
