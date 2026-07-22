import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/user_service.dart';

import 'product_detail_screen.dart';

const List<String> kProductCategories = [
  "Elektronik",
  "Giyim",
  "Ev & Yaşam",
  "Araç",
  "Emlak",
  "Hobi",
  "Kitap",
  "Spor",
  "Diğer",
];

const List<String> kProductConditions = ["Sıfır", "İkinci El"];

class PiPazarScreen extends StatefulWidget {
  const PiPazarScreen({super.key});

  @override
  State<PiPazarScreen> createState() => _PiPazarScreenState();
}

class _PiPazarScreenState extends State<PiPazarScreen> {
  static const Color primaryColor = Color(0xFF5B2D90);

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final locationController = TextEditingController();
  final searchController = TextEditingController();

  String selectedCategory = kProductCategories.first;
  String selectedCondition = kProductConditions.first;
  bool negotiable = false;

  String activeCategoryFilter = "Tümü";

  List products = [];
  List filteredProducts = [];
  Set<int> favoriteProducts = {};
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadProducts();
    loadFavorites();
  }

  Future<List<String>> uploadImages(List<File> images) async {
    List<String> uploaded = [];

    for (final file in images) {
      try {
        var request = http.MultipartRequest(
          "POST",
          Uri.parse(
            "https://lifeos.cadinindiyari.com/api/upload_product_image.php",
          ),
        );

        request.files.add(
          await http.MultipartFile.fromPath("image", file.path),
        );

        final response = await request.send();
        final responseString = await response.stream.bytesToString();
        final data = jsonDecode(responseString);

        if (data["success"] == true) {
          uploaded.add(data["path"].toString());
        }
      } catch (e) {
        debugPrint("uploadImages hata: $e");
      }
    }

    return uploaded;
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
          applyFilters();
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

  void applyFilters() {
    final query = searchController.text.toLowerCase();

    filteredProducts = products.where((product) {
      final title = product["title"].toString().toLowerCase();
      final description = product["description"].toString().toLowerCase();

      final matchesQuery =
          query.isEmpty || title.contains(query) || description.contains(query);

      final matchesCategory =
          activeCategoryFilter == "Tümü" ||
          product["category"].toString() == activeCategoryFilter;

      return matchesQuery && matchesCategory;
    }).toList();
  }

  void searchProducts(String value) {
    setState(() {
      applyFilters();
    });
  }

  void selectCategoryFilter(String category) {
    setState(() {
      activeCategoryFilter = category;
      applyFilters();
    });
  }

  Future<void> createProduct(List<File> images) async {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
      );
      return;
    }

    try {
      List<String> uploadedPaths = await uploadImages(images);
      String coverImage = uploadedPaths.isNotEmpty ? uploadedPaths.first : "";

      final response = await http.post(
        Uri.parse("https://lifeos.cadinindiyari.com/api/create_product.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": UserService.id,
          "title": titleController.text.trim(),
          "description": descriptionController.text.trim(),
          "price": priceController.text.trim(),
          "image": coverImage,
          "images": uploadedPaths,
          "category": selectedCategory,
          "condition_status": selectedCondition,
          "location": locationController.text.trim(),
          "negotiable": negotiable ? 1 : 0,
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
        locationController.clear();

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

      if (!mounted) return;

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

  Future<void> toggleSold(int productId) async {
    try {
      final response = await http.post(
        Uri.parse("https://lifeos.cadinindiyari.com/api/toggle_sold.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": UserService.id, "product_id": productId}),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        await loadProducts();
      }
    } catch (e) {
      debugPrint("toggleSold hata: $e");
    }
  }

  Future<void> updateProduct(
    int productId,
    String title,
    String description,
    String price,
    String category,
    String condition,
    String location,
    bool isNegotiable,
    List<File> images,
  ) async {
    try {
      List<String> newUploadedPaths = [];
      String coverImage = "";

      // Yeni resim(ler) seçilmişse yükle
      if (images.isNotEmpty) {
        newUploadedPaths = await uploadImages(images);
        coverImage = newUploadedPaths.isNotEmpty ? newUploadedPaths.first : "";
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
          "image": coverImage,
          "images": newUploadedPaths,
          "category": category,
          "condition_status": condition,
          "location": location,
          "negotiable": isNegotiable ? 1 : 0,
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

    final editLocationController = TextEditingController(
      text: item["location"]?.toString() ?? "",
    );

    String editCategory =
        kProductCategories.contains(item["category"]?.toString())
        ? item["category"].toString()
        : kProductCategories.first;

    String editCondition =
        kProductConditions.contains(item["condition_status"]?.toString())
        ? item["condition_status"].toString()
        : kProductConditions.first;

    bool editNegotiable = item["negotiable"].toString() == "1";

    List<File> editImages = [];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
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

                    DropdownButtonFormField<String>(
                      initialValue: editCategory,
                      decoration: const InputDecoration(labelText: "Kategori"),
                      items: kProductCategories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => editCategory = value);
                        }
                      },
                    ),

                    const SizedBox(height: 15),

                    RadioGroup<String>(
                      groupValue: editCondition,
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => editCondition = value);
                        }
                      },
                      child: Row(
                        children: kProductConditions.map((c) {
                          return Expanded(
                            child: RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                c,
                                style: const TextStyle(fontSize: 13),
                              ),
                              value: c,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    TextField(
                      controller: editLocationController,
                      decoration: const InputDecoration(
                        labelText: "Konum (ör. İstanbul)",
                      ),
                    ),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Pazarlık payı var"),
                      value: editNegotiable,
                      onChanged: (value) {
                        setDialogState(() => editNegotiable = value);
                      },
                    ),

                    const SizedBox(height: 10),

                    ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await picker.pickMultiImage(
                          imageQuality: 80,
                        );
                        if (picked.isNotEmpty) {
                          setDialogState(() {
                            editImages.addAll(picked.map((x) => File(x.path)));
                          });
                        }
                      },
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text("Yeni Fotoğraf(lar) Ekle"),
                    ),

                    const SizedBox(height: 10),

                    if (editImages.isNotEmpty)
                      SizedBox(
                        height: 90,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(editImages.length, (i) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        editImages[i],
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () {
                                          setDialogState(
                                            () => editImages.removeAt(i),
                                          );
                                        },
                                        child: const CircleAvatar(
                                          radius: 11,
                                          backgroundColor: Colors.black54,
                                          child: Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
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
                    await updateProduct(
                      int.parse(item["id"].toString()),
                      editTitleController.text.trim(),
                      editDescriptionController.text.trim(),
                      editPriceController.text.trim(),
                      editCategory,
                      editCondition,
                      editLocationController.text.trim(),
                      editNegotiable,
                      editImages,
                    );

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text("Kaydet"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showAddDialog() {
    titleController.clear();
    descriptionController.clear();
    priceController.clear();
    locationController.clear();
    selectedCategory = kProductCategories.first;
    selectedCondition = kProductConditions.first;
    negotiable = false;

    List<File> addImages = [];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
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

                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: "Kategori"),
                      items: kProductCategories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedCategory = value);
                        }
                      },
                    ),

                    const SizedBox(height: 15),

                    RadioGroup<String>(
                      groupValue: selectedCondition,
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedCondition = value);
                        }
                      },
                      child: Row(
                        children: kProductConditions.map((c) {
                          return Expanded(
                            child: RadioListTile<String>(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                c,
                                style: const TextStyle(fontSize: 13),
                              ),
                              value: c,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: "Konum (ör. İstanbul)",
                      ),
                    ),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Pazarlık payı var"),
                      value: negotiable,
                      onChanged: (value) {
                        setDialogState(() => negotiable = value);
                      },
                    ),

                    const SizedBox(height: 10),

                    ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await picker.pickMultiImage(
                          imageQuality: 80,
                        );
                        if (picked.isNotEmpty) {
                          setDialogState(() {
                            addImages.addAll(picked.map((x) => File(x.path)));
                          });
                        }
                      },
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text("Fotoğraf(lar) Seç"),
                    ),

                    const SizedBox(height: 10),

                    if (addImages.isNotEmpty)
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: addImages.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    addImages[i],
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () {
                                      setDialogState(
                                        () => addImages.removeAt(i),
                                      );
                                    },
                                    child: const CircleAvatar(
                                      radius: 11,
                                      backgroundColor: Colors.black54,
                                      child: Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
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
                    await createProduct(addImages);

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text("Kaydet"),
                ),
              ],
            );
          },
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
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
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

          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              children: ["Tümü", ...kProductCategories].map((category) {
                final isActive = category == activeCategoryFilter;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isActive,
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(
                      color: isActive ? Colors.white : Colors.black87,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (_) => selectCategoryFilter(category),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(child: Text("İlan bulunamadı."))
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final item = filteredProducts[index];
                      final isSold = item["sold"].toString() == "1";
                      final isNegotiable = item["negotiable"].toString() == "1";

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
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Opacity(
                                          opacity: isSold ? 0.4 : 1,
                                          child: Image.network(
                                            item["image"].toString(),
                                            width: double.infinity,
                                            height: 220,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      if (isSold)
                                        Positioned.fill(
                                          child: Center(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 18,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                "SATILDI",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
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

                                const SizedBox(height: 10),

                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if ((item["category"] ?? "")
                                        .toString()
                                        .isNotEmpty)
                                      Chip(
                                        label: Text(
                                          item["category"].toString(),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    if ((item["condition_status"] ?? "")
                                        .toString()
                                        .isNotEmpty)
                                      Chip(
                                        label: Text(
                                          item["condition_status"].toString(),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    if (isNegotiable)
                                      const Chip(
                                        label: Text(
                                          "Pazarlıklı",
                                          style: TextStyle(fontSize: 11),
                                        ),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                  ],
                                ),

                                if ((item["location"] ?? "")
                                    .toString()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 15,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item["location"].toString(),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

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
                                        icon: Icon(
                                          isSold
                                              ? Icons.undo_rounded
                                              : Icons.sell_rounded,
                                          color: Colors.blueGrey,
                                        ),
                                        tooltip: isSold
                                            ? "Satıldı işaretini kaldır"
                                            : "Satıldı olarak işaretle",
                                        onPressed: () {
                                          toggleSold(
                                            int.parse(item["id"].toString()),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.orange,
                                        ),
                                        onPressed: () {
                                          showEditDialog(item);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
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
