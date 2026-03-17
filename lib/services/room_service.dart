import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';
import '../models/daily_price_model.dart';
import '../DTOs/create_room_dto.dart';
import '../DTOs/update_room_dto.dart';
import '../DTOs/set_daily_price_dto.dart';
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

  /// Create a new room from a [CreateRoomDTO].
  Future<String> createRoom(CreateRoomDTO dto) async {
    final error = dto.validate();
    if (error != null) throw Exception(error);

    final docRef =
        await _firestore.collection('rooms').add(dto.toModel().toMap());
    return docRef.id;
  }

  /// Update an existing room using [UpdateRoomDTO].
  /// Fetches the current room doc, merges changes, then persists.
  Future<void> updateRoom(UpdateRoomDTO dto) async {
    final error = dto.validate();
    if (error != null) throw Exception(error);

    final doc =
        await _firestore.collection('rooms').doc(dto.roomId).get();
    if (!doc.exists) throw Exception('Phòng không tồn tại');

    final existing = RoomModel.fromMap(doc.data()!, doc.id);
    final updated = dto.applyTo(existing);
    await _firestore
        .collection('rooms')
        .doc(dto.roomId)
        .update(updated.toMap());
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

  // Fetch daily price overrides in a date range (inclusive by day).
  Future<List<DailyPriceModel>> getDailyPricesInRange(
    String roomId,
    DateTime from,
    DateTime to,
  ) async {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
    final snap = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('daily_prices')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return snap.docs
        .map((doc) => DailyPriceModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Set or update a specific day's price/block status using [SetDailyPriceDTO].
  Future<void> setDailyPrice(SetDailyPriceDTO dto) async {
    final error = dto.validate();
    if (error != null) throw Exception(error);

    final dateKey = DateFormat('yyyy-MM-dd').format(dto.date);
    await _firestore
        .collection('rooms')
        .doc(dto.roomId)
        .collection('daily_prices')
        .doc(dateKey)
        .set(dto.toModel().toMap(), SetOptions(merge: true));
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
