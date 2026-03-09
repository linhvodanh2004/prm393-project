import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/daily_price_model.dart';

class CalendarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate a consistent ID: "roomId_YYYY-MM-DD"
  String _generateId(String roomId, DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return '${roomId}_$dateStr';
  }

  // Stream prices for a specific room
  Stream<List<DailyPriceModel>> getDailyPricesForRoom(String roomId) {
    return _firestore
        .collection('daily_prices')
        .where('roomId', isEqualTo: roomId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DailyPriceModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Save or update a daily price/availability flag
  Future<void> saveDailyPrice(
    String roomId,
    DateTime date,
    double price,
    bool isBlocked,
  ) async {
    final docId = _generateId(roomId, date);
    final model = DailyPriceModel(
      id: docId,
      roomId: roomId,
      date: date,
      price: price,
      isBlocked: isBlocked,
    );
    await _firestore
        .collection('daily_prices')
        .doc(docId)
        .set(model.toMap(), SetOptions(merge: true));
  }
}
