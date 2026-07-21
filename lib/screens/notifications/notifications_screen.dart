import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/user_service.dart';
import '../chat/chat_screen.dart';
import '../profile/user_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color primaryColor = Color(0xFF5B2D90);

  bool loading = true;
  List notifications = [];

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/get_notifications.php"
          "?user_id=${UserService.id}",
        ),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        loading = false;
        if (data["success"] == true) {
          notifications = data["notifications"] ?? [];
        }
      });
    } catch (e) {
      debugPrint("loadNotifications hata: $e");
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> markAsRead({int? notificationId}) async {
    try {
      await http.post(
        Uri.parse(
          "https://lifeos.cadinindiyari.com/api/mark_notification_read.php",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": UserService.id,
          "notification_id": ?notificationId,
        }),
      );
    } catch (e) {
      debugPrint("markAsRead hata: $e");
    }
  }

  Future<void> markAllAsRead() async {
    await markAsRead();
    if (!mounted) return;
    setState(() {
      notifications = notifications.map((n) {
        n["is_read"] = 1;
        return n;
      }).toList();
    });
  }

  IconData iconFor(String type) {
    switch (type) {
      case "follow":
        return Icons.person_add_rounded;
      case "message":
        return Icons.chat_bubble_rounded;
      case "favorite":
        return Icons.favorite_rounded;
      case "sale":
        return Icons.sell_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color colorFor(String type) {
    switch (type) {
      case "follow":
        return Colors.blue;
      case "message":
        return Colors.green;
      case "favorite":
        return Colors.red;
      case "sale":
        return Colors.orange;
      default:
        return primaryColor;
    }
  }

  String timeAgo(String createdAt) {
    try {
      final date = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(date);

      if (diff.inMinutes < 1) return "Şimdi";
      if (diff.inMinutes < 60) return "${diff.inMinutes} dk önce";
      if (diff.inHours < 24) return "${diff.inHours} sa önce";
      if (diff.inDays < 7) return "${diff.inDays} gün önce";
      return "${date.day}.${date.month}.${date.year}";
    } catch (e) {
      return "";
    }
  }

  String extractUsername(dynamic notif) {
    final text = "${notif["title"] ?? ""} ${notif["body"] ?? ""}";
    final match = RegExp(r"@(\S+)").firstMatch(text);
    return match?.group(1) ?? "";
  }

  Future<void> handleTap(dynamic notif) async {
    if (notif["is_read"] != 1) {
      await markAsRead(notificationId: int.parse(notif["id"].toString()));
      if (mounted) {
        setState(() {
          notif["is_read"] = 1;
        });
      }
    }

    if (!mounted) return;

    final type = notif["type"].toString();
    final relatedId = notif["related_id"];

    if (relatedId == null) return;

    final username = extractUsername(notif);

    if (type == "follow") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(
            userId: int.parse(relatedId.toString()),
            username: username,
          ),
        ),
      );
    } else if (type == "message") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            receiverId: int.parse(relatedId.toString()),
            receiverName: username,
          ),
        ),
      );
    } else if (type == "favorite") {
      // related_id burada ürün id'si — ürün bilgisi taşınmadığı için
      // basit bir yaklaşımla sadece detay ekranına id ile gitmiyoruz,
      // ileride get_product.php eklenirse buradan yönlendirilebilir.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text("Bildirimler"),
        centerTitle: true,
        actions: [
          if (notifications.any((n) => n["is_read"] != 1))
            TextButton(
              onPressed: markAllAsRead,
              child: const Text(
                "Tümünü Okundu Yap",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(child: Text("Henüz bildiriminiz yok."))
          : RefreshIndicator(
              onRefresh: loadNotifications,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final isRead = notif["is_read"] == 1;
                  final type = notif["type"].toString();

                  return InkWell(
                    onTap: () => handleTap(notif),
                    child: Container(
                      color: isRead
                          ? Colors.white
                          : primaryColor.withValues(alpha: 0.06),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: colorFor(
                              type,
                            ).withValues(alpha: 0.15),
                            child: Icon(iconFor(type), color: colorFor(type)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notif["title"]?.toString() ?? "",
                                  style: TextStyle(
                                    fontWeight: isRead
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  notif["body"]?.toString() ?? "",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeAgo(
                                    notif["created_at"]?.toString() ?? "",
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: const BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
