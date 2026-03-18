import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
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

    var model = dto.toModel();

    // Lấy Location mặc định từ Host Property để gán cho Room này
    try {
      final propertyDoc = await _firestore.collection('properties').doc(model.hostId).get();
      if (propertyDoc.exists && propertyDoc.data() != null) {
        final location = propertyDoc.data()!['location'];
        if (location != null) {
          model = model.copyWith(location: location as Map<String, dynamic>);
        }
      }
    } catch (e) {
      print('Error fetching property location: $e');
    }

    final docRef =
        await _firestore.collection('rooms').add(model.toMap());
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

  // Khám phá theo Bán Kính: Tìm kiếm phòng nằm trong phạm vi (Vĩ độ, Kinh độ, km)
  Stream<List<RoomModel>> getRoomsWithinRadius({
    required double lat,
    required double lng,
    required double radiusInKm,
  }) {
    final center = GeoFirePoint(GeoPoint(lat, lng));
    final collectionReference = _firestore.collection('rooms');

    return GeoCollectionReference(collectionReference)
        .subscribeWithin(
          center: center,
          radiusInKm: radiusInKm,
          field: 'location',
          geopointFrom: (data) {
            final loc = data['location'] as Map<String, dynamic>?;
            if (loc != null && loc['geopoint'] != null) {
              return loc['geopoint'] as GeoPoint;
            }
            // Fallback (rooms without location will never be matched properly anyway)
            return const GeoPoint(0, 0); 
          },
          queryBuilder: (query) => query.where('status', isEqualTo: 'available'),
          strictMode: true,
        )
        .map((docs) => docs
            .map((doc) => RoomModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
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
