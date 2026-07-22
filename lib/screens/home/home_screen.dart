import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/user_service.dart';

import '../notes/notes_screen.dart';
import '../profile/profile_screen.dart';
import '../tasks/task_screen.dart';
import '../settings/settings_screen.dart';
import '../news/news_screen.dart';
import '../pipazar/pi_pazar_screen.dart';
import '../pipazar/favorites_screen.dart';
import '../pipazar/my_products_screen.dart';
import '../pipazar/product_detail_screen.dart';
import '../chat/conversations_screen.dart';
import '../notifications/notifications_screen.dart';
import '../calendar/calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryColor = Color(0xFF5B2D90);
  static const Color accentColor = Color(0xFFF4AF2C);
  static const Color backgroundColor = Color(0xFFF7F5FC);

  bool loading = true;

  List recentProducts = [];
  List announcements = [];
  String? piPrice;
  int unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/get_dashboard.php"
          "?user_id=${UserService.id}",
        ),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        loading = false;

        if (data["success"] == true) {
          recentProducts = data["recent_products"] ?? [];
          announcements = data["announcements"] ?? [];
          piPrice = data["pi_price"]?.toString();
          unreadNotifications =
              int.tryParse(data["unread_notifications"].toString()) ?? 0;
        }
      });
    } catch (e) {
      debugPrint("loadDashboard hata: $e");

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
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "PiLife",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_rounded),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                  loadDashboard();
                },
              ),
              if (unreadNotifications > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadNotifications > 9
                          ? "9+"
                          : unreadNotifications.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: loadDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 10),

              const Text(
                "Hoş Geldin 👋",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "${UserService.fullname} (@${UserService.username})",
                style: const TextStyle(
                  fontSize: 18,
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                "Bugün ne yapmak istiyorsun?",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 25),

              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                // Pi fiyat bilgisi
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          "π",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Pi Fiyatı",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (piPrice != null && piPrice!.isNotEmpty)
                                  ? piPrice!
                                  : "Yakında",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Duyurular
                if (announcements.isNotEmpty) ...[
                  const SizedBox(height: 25),
                  const Text(
                    "Günün Duyuruları",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...announcements.map(
                    (a) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.campaign_rounded,
                            color: accentColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a["title"]?.toString() ?? "",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  a["message"]?.toString() ?? "",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Son eklenen ilanlar
                if (recentProducts.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  const Text(
                    "Son Eklenen İlanlar",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 170,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recentProducts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final item = recentProducts[index];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(item: item),
                              ),
                            );
                          },
                          child: Container(
                            width: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                item["image"] != null &&
                                        item["image"].toString().isNotEmpty
                                    ? Image.network(
                                        item["image"].toString(),
                                        height: 90,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 90,
                                        width: double.infinity,
                                        color: backgroundColor,
                                        child: const Icon(Icons.image),
                                      ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item["title"]?.toString() ?? "",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${item["price"]} Pi",
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 25),
              ],

              const Text(
                "Hızlı Menü",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),

              const SizedBox(height: 15),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.10,

                children: [
                  kart(
                    context,
                    Icons.shopping_cart_rounded,
                    "Pi Pazar",
                    const PiPazarScreen(),
                  ),
                  kart(
                    context,
                    Icons.storefront,
                    "İlanlarım",
                    const MyProductsScreen(),
                  ),
                  kart(
                    context,
                    Icons.favorite_rounded,
                    "Favoriler",
                    const FavoritesScreen(),
                  ),

                  kart(
                    context,
                    Icons.message_rounded,
                    "Mesajlar",
                    const ConversationsScreen(),
                  ),

                  kart(
                    context,
                    Icons.note_alt_rounded,
                    "Notlar",
                    const NotesScreen(),
                  ),

                  kart(
                    context,
                    Icons.task_alt_rounded,
                    "Görevler",
                    const TaskScreen(),
                  ),

                  kart(
                    context,
                    Icons.calendar_month_rounded,
                    "Takvim",
                    const CalendarScreen(),
                  ),

                  kart(
                    context,
                    Icons.account_circle_rounded,
                    "Profil",
                    const ProfileScreen(),
                  ),

                  kart(
                    context,
                    Icons.newspaper_rounded,
                    "Haberler",
                    const NewsScreen(),
                  ),

                  kart(
                    context,
                    Icons.settings_rounded,
                    "Ayarlar",
                    const SettingsScreen(),
                  ),
                ],
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  static Widget kart(
    BuildContext context,
    IconData icon,
    String text,
    Widget page,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),

      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },

      child: Card(
        color: Colors.white,
        elevation: 6,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              width: 72,
              height: 72,

              decoration: const BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),

              child: Icon(icon, size: 38, color: primaryColor),
            ),

            const SizedBox(height: 18),

            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
