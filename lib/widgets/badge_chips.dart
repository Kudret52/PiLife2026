import 'package:flutter/material.dart';

IconData badgeIcon(String code) {
  switch (code) {
    case "new_member":
      return Icons.emoji_nature_rounded;
    case "verified_seller":
      return Icons.verified_rounded;
    case "premium":
      return Icons.workspace_premium_rounded;
    case "trusted_seller":
      return Icons.shield_rounded;
    case "top_seller":
      return Icons.local_fire_department_rounded;
    case "most_followed":
      return Icons.star_rounded;
    default:
      return Icons.military_tech_rounded;
  }
}

Color badgeColor(String code) {
  switch (code) {
    case "new_member":
      return Colors.green;
    case "verified_seller":
      return Colors.blue;
    case "premium":
      return Colors.amber.shade800;
    case "trusted_seller":
      return const Color(0xFF5B2D90);
    case "top_seller":
      return Colors.deepOrange;
    case "most_followed":
      return Colors.pink;
    default:
      return Colors.grey;
  }
}

/// Verilen rozet listesini (her biri {"code":..., "label":...} şeklinde)
/// renkli chip'ler olarak gösteren widget. Boşsa hiçbir şey göstermez.
class BadgeChips extends StatelessWidget {
  final List badges;

  const BadgeChips({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: badges.map((b) {
        final code = b["code"]?.toString() ?? "";
        final label = b["label"]?.toString() ?? "";

        return Chip(
          avatar: Icon(badgeIcon(code), size: 16, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: badgeColor(code),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}
