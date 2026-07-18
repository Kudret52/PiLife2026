import 'package:flutter/material.dart';

import '../../services/user_service.dart';

import '../notes/notes_screen.dart';
import '../profile/profile_screen.dart';
import '../tasks/task_screen.dart';
import '../settings/settings_screen.dart';
import '../news/news_screen.dart';
import '../pipazar/pi_pazar_screen.dart';
import '../pipazar/favorites_screen.dart';
import '../pipazar/my_products_screen.dart';
import '../chat/conversations_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color primaryColor = Color(0xFF5B2D90);
  static const Color accentColor = Color(0xFFF4AF2C);
  static const Color backgroundColor = Color(0xFFF7F5FC);

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
      ),

      body: Padding(
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

            Expanded(
              child: GridView.count(
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
            ),
          ],
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
