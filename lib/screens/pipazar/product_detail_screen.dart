import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/user_service.dart';
import '../chat/chat_screen.dart';
import '../profile/user_profile_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final dynamic item;

  const ProductDetailScreen({super.key, required this.item});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Map item = Map.from(widget.item);
  bool togglingSold = false;

  List<Map> extraImages = [];
  int currentImageIndex = 0;
  final PageController pageController = PageController();

  List comments = [];
  double avgRating = 0;
  int totalRatings = 0;
  bool loadingComments = true;

  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    loadExtraImages();
    loadComments();
    checkFavoriteStatus();
  }

  Future<void> checkFavoriteStatus() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/get_user_favorites.php"
          "?user_id=${UserService.id}",
        ),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (data["success"] == true) {
        final favorites = List.from(data["favorites"] ?? []);
        final productId = int.tryParse(item["id"].toString());

        setState(() {
          isFavorite = favorites.any(
            (f) => int.tryParse(f.toString()) == productId,
          );
        });
      }
    } catch (e) {
      debugPrint("checkFavoriteStatus hata: $e");
    }
  }

  Future<void> loadComments() async {
    try {
      final commentsResponse = await http.get(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/get_comments.php"
          "?product_id=${item["id"]}",
        ),
      );

      final ratingResponse = await http.get(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/get_rating.php"
          "?product_id=${item["id"]}",
        ),
      );

      final commentsData = jsonDecode(commentsResponse.body);
      final ratingData = jsonDecode(ratingResponse.body);

      if (!mounted) return;

      setState(() {
        loadingComments = false;

        if (commentsData["success"] == true) {
          comments = commentsData["comments"] ?? [];
        }

        if (ratingData["success"] == true && ratingData["rating"] != null) {
          final avg = ratingData["rating"]["avg_rating"];
          final total = ratingData["rating"]["total"];
          avgRating = avg != null ? double.tryParse(avg.toString()) ?? 0 : 0;
          totalRatings = total != null
              ? int.tryParse(total.toString()) ?? 0
              : 0;
        }
      });
    } catch (e) {
      debugPrint("loadComments hata: $e");
      if (mounted) setState(() => loadingComments = false);
    }
  }

  Future<void> submitReview(int rating, String comment) async {
    try {
      final response = await http.post(
        Uri.parse("https://lifeos.cadinindiyari.com/api/add_comment.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "product_id": item["id"],
          "user_id": UserService.id,
          "rating": rating,
          "comment": comment,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (data["success"] == true) {
        await loadComments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Değerlendirmeniz eklendi.")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"]?.toString() ?? "Bir hata oluştu."),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  void showReviewDialog() {
    int selectedStars = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text("Değerlendirme Yap"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final starValue = i + 1;
                        return IconButton(
                          onPressed: () {
                            setDialogState(() => selectedStars = starValue);
                          },
                          icon: Icon(
                            starValue <= selectedStars
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Yorumunuz",
                        hintText: "Ürün/satıcı hakkındaki deneyiminizi yazın",
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
                    if (commentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text("Lütfen bir yorum yazın."),
                        ),
                      );
                      return;
                    }

                    submitReview(selectedStars, commentController.text.trim());

                    Navigator.pop(dialogContext);
                  },
                  child: const Text("Gönder"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> loadExtraImages() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/get_product_images.php"
          "?product_id=${item["id"]}",
        ),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true && mounted) {
        setState(() {
          extraImages = List<Map>.from(data["images"] ?? []);
        });
      }
    } catch (e) {
      debugPrint("loadExtraImages hata: $e");
    }
  }

  Future<void> deleteExtraImage(int imageId) async {
    try {
      final response = await http.post(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/delete_product_image.php",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"image_id": imageId, "user_id": UserService.id}),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        await loadExtraImages();
      }
    } catch (e) {
      debugPrint("deleteExtraImage hata: $e");
    }
  }

  Future<void> addFavorite(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse("https://lifeos.cadinindiyari.com/api/toggle_favorite.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": UserService.id,
          "product_id": int.parse(item["id"].toString()),
        }),
      );

      final data = jsonDecode(response.body);

      if (!context.mounted) return;

      if (data["success"] == true) {
        setState(() {
          isFavorite = data["favorite"] == true;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data["success"] == true
                ? (isFavorite
                      ? "Favorilere eklendi."
                      : "Favorilerden çıkarıldı.")
                : "Favori işlemi sırasında bir hata oluştu.",
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    }
  }

  Future<void> toggleSold() async {
    setState(() => togglingSold = true);

    try {
      final response = await http.post(
        Uri.parse("https://lifeos.cadinindiyari.com/api/toggle_sold.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": UserService.id,
          "product_id": int.parse(item["id"].toString()),
        }),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true && mounted) {
        setState(() {
          item["sold"] = data["sold"] == true ? "1" : "0";
        });
      }
    } catch (e) {
      debugPrint("toggleSold hata: $e");
    } finally {
      if (mounted) setState(() => togglingSold = false);
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner =
        item["user_id"].toString() == UserService.id.toString();
    final bool isSold = item["sold"].toString() == "1";
    final bool isNegotiable = item["negotiable"].toString() == "1";
    final String category = (item["category"] ?? "").toString();
    final String condition = (item["condition_status"] ?? "").toString();
    final String location = (item["location"] ?? "").toString();

    return Scaffold(
      appBar: AppBar(title: Text(item["title"].toString()), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) {
                final List<String> allImages = [
                  if (item["image"] != null &&
                      item["image"].toString().isNotEmpty)
                    item["image"].toString(),
                  ...extraImages.map((e) => e["image_path"].toString()),
                ];

                if (allImages.isEmpty) return const SizedBox();

                return Stack(
                  children: [
                    SizedBox(
                      height: 300,
                      child: PageView.builder(
                        controller: pageController,
                        itemCount: allImages.length,
                        onPageChanged: (index) {
                          setState(() => currentImageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          final isExtra = index > 0 || item["image"] == null;
                          final extraIndex =
                              (item["image"] != null &&
                                  item["image"].toString().isNotEmpty)
                              ? index - 1
                              : index;

                          return Stack(
                            children: [
                              Opacity(
                                opacity: isSold ? 0.4 : 1,
                                child: Image.network(
                                  allImages[index],
                                  width: double.infinity,
                                  height: 300,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (isOwner &&
                                  isExtra &&
                                  extraIndex >= 0 &&
                                  extraIndex < extraImages.length)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: GestureDetector(
                                    onTap: () {
                                      deleteExtraImage(
                                        int.parse(
                                          extraImages[extraIndex]["id"]
                                              .toString(),
                                        ),
                                      );
                                    },
                                    child: const CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      child: Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),

                    if (isSold)
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "SATILDI",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),

                    if (allImages.length > 1)
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(allImages.length, (i) {
                            return Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == currentImageIndex
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                );
              },
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

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (category.isNotEmpty) Chip(label: Text(category)),
                      if (condition.isNotEmpty) Chip(label: Text(condition)),
                      if (isNegotiable) const Chip(label: Text("Pazarlıklı")),
                    ],
                  ),

                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 18,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],

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

                  if (isOwner) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        icon: Icon(
                          isSold ? Icons.undo_rounded : Icons.sell_rounded,
                        ),
                        label: Text(
                          togglingSold
                              ? "İşleniyor..."
                              : (isSold
                                    ? "Satıldı İşaretini Kaldır"
                                    : "Satıldı Olarak İşaretle"),
                        ),
                        onPressed: togglingSold ? null : toggleSold,
                      ),
                    ),
                    const SizedBox(height: 15),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isFavorite
                              ? Colors.white
                              : Colors.red,
                          backgroundColor: isFavorite
                              ? Colors.red
                              : Colors.transparent,
                          side: const BorderSide(color: Colors.red),
                        ),
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                        ),
                        label: Text(
                          isFavorite ? "Favorilerden Çıkar" : "Favorilere Ekle",
                        ),
                        onPressed: () => addFavorite(context),
                      ),
                    ),

                    const SizedBox(height: 15),

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

                  const SizedBox(height: 35),

                  const Divider(),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      const Text(
                        "Değerlendirmeler",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (totalRatings > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                        Text(
                          " ${avgRating.toStringAsFixed(1)} ($totalRatings)",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),

                  if (!isOwner)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: showReviewDialog,
                        icon: const Icon(Icons.rate_review_outlined),
                        label: const Text("Yorum Yap"),
                      ),
                    ),

                  const SizedBox(height: 10),

                  if (loadingComments)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (comments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        "Henüz değerlendirme yapılmamış.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...comments.map((c) {
                      final stars = int.tryParse(c["rating"].toString()) ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    c["username"]?.toString() ?? "",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: List.generate(5, (i) {
                                      return Icon(
                                        i < stars
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        color: Colors.amber,
                                        size: 15,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(c["comment"]?.toString() ?? ""),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
