import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import '../models/property_model.dart';
import '../DTOs/save_property_dto.dart';

class PropertyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Since it's a 1:1 relationship between Host and Property in this MVP,
  // we will use the hostId as the Document ID inside the 'properties' collection

  // Stream a host's property profile
  Stream<PropertyModel?> getPropertyByHost(String hostId) {
    return _firestore.collection('properties').doc(hostId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        return PropertyModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  /// Create or update a property profile from a [SavePropertyDTO].
  Future<void> saveProperty(SavePropertyDTO dto) async {
    final error = dto.validate();
    if (error != null) throw Exception(error);

    var model = dto.toModel();

    // Dịch ngầm chuỗi địa chỉ ra Tọa độ (Geocoding)
    try {
      List<Location> locations = await locationFromAddress(model.address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final geoPoint = GeoPoint(loc.latitude, loc.longitude);
        final geoFirePoint = GeoFirePoint(geoPoint);
        
        model = model.copyWith(location: {
          'geohash': geoFirePoint.geohash,
          'geopoint': geoPoint,
        });
      }
    } catch (e) {
      print('Lỗi Geocoding địa chỉ (có thể sai format Tỉnh/Phường): $e');
    }

    // Lưu property
    await _firestore
        .collection('properties')
        .doc(dto.hostId)
        .set(model.toMap(), SetOptions(merge: true));

    // Cascade vòng lặp: Nếu property có Tọa độ, ta cập nhật Location xuống TẤT CẢ các phòng của Host này
    // Để khi User tìm kiếm bán kính Phòng, nó sẽ fetch ra chính xác đồ của Host.
    if (model.location != null) {
      final roomsSnap = await _firestore
          .collection('rooms')
          .where('hostId', isEqualTo: model.hostId)
          .get();
      
      if (roomsSnap.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in roomsSnap.docs) {
          batch.update(doc.reference, {'location': model.location});
        }
        await batch.commit();
      }
    }
  }
}
