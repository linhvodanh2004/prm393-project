import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';
import '../models/daily_price_model.dart';
import 'package:intl/intl.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -- Room CRUD --

  // Stream a host's rooms
  Stream<List<RoomModel>> getRoomsByHost(String hostId) {
    return _firestore
        .collection('rooms')
        .where('hostId', isEqualTo: hostId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RoomModel.fromMap(doc.data(), doc.id))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  // Create a new room
  Future<String> createRoom(RoomModel room) async {
    final docRef = await _firestore.collection('rooms').add(room.toMap());
    return docRef.id;
  }

  // Update an existing room
  Future<void> updateRoom(RoomModel room) async {
    await _firestore.collection('rooms').doc(room.id).update(room.toMap());
  }

  // Delete a room
  Future<void> deleteRoom(String roomId) async {
    await _firestore.collection('rooms').doc(roomId).delete();
  }

  // -- Calendar / Daily Prices --

  // Stream daily price overrides for a specific room within a month
  Stream<List<DailyPriceModel>> getDailyPrices(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('daily_prices')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DailyPriceModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Set or update a specific day's price/block status
  Future<void> setDailyPrice(DailyPriceModel dailyPrice) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(dailyPrice.date);
    await _firestore
        .collection('rooms')
        .doc(dailyPrice.roomId)
        .collection('daily_prices')
        .doc(dateKey)
        .set(dailyPrice.toMap(), SetOptions(merge: true));
  }

  // Remove an override to revert back to the room's basePrice
  Future<void> clearDailyPrice(String roomId, DateTime date) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('daily_prices')
        .doc(dateKey)
        .delete();
  }
}
