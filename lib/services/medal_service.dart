import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum MedalTier { NONE, COPPER, BRONZE, SILVER, GOLD }

class MedalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<MedalTier> getMedalTier(String userId, {bool isHost = false}) async {
    try {
      final field = isHost ? 'hostId' : 'userId';
      final aggregateQuery = await _firestore
          .collection('bookings')
          .where(field, isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .count()
          .get();

      final count = aggregateQuery.count ?? 0;

      if (count >= 50) return MedalTier.GOLD;
      if (count >= 20) return MedalTier.SILVER;
      if (count >= 10) return MedalTier.BRONZE;
      return MedalTier.COPPER; // Dưới 10 booking thì vĩnh viễn là COPPER
    } catch (e) {
      debugPrint('Error getting medal tier: $e');
      return MedalTier.NONE;
    }
  }

  static Widget buildMedalBadge(MedalTier tier, {double iconSize = 16, double fontSize = 12}) {
    if (tier == MedalTier.NONE) return const SizedBox.shrink();

    Color color;
    String text;
    IconData iconData = Icons.emoji_events;

    switch (tier) {
      case MedalTier.COPPER:
        color = const Color(0xFFB87333); // Copper
        text = 'Hạng Sơ Cấp'; 
        break;
      case MedalTier.BRONZE:
        color = const Color(0xFFCD7F32); // Bronze
        text = 'Hạng Đồng';
        break;
      case MedalTier.SILVER:
        color = const Color(0xFFC0C0C0); // Silver
        text = 'Hạng Bạc';
        break;
      case MedalTier.GOLD:
        color = const Color(0xFFFFD700); // Gold
        text = 'Hạng Vàng';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: color, size: iconSize),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
