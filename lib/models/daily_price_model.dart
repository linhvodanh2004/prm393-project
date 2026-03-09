import 'package:cloud_firestore/cloud_firestore.dart';

class DailyPriceModel {
  final String id; // usually the date string like 'YYYY-MM-DD'
  final String roomId;
  final DateTime date;
  final double price; // The overridden price for this specific date
  final bool isBlocked; // If true, the room is unavailable on this date

  DailyPriceModel({
    required this.id,
    required this.roomId,
    required this.date,
    required this.price,
    this.isBlocked = false,
  });

  factory DailyPriceModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return DailyPriceModel(
      id: documentId,
      roomId: data['roomId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      price: (data['price'] ?? 0).toDouble(),
      isBlocked: data['isBlocked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'date': Timestamp.fromDate(date),
      'price': price,
      'isBlocked': isBlocked,
    };
  }
}
