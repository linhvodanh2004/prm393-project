import 'package:cloud_firestore/cloud_firestore.dart';
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

    await _firestore
        .collection('properties')
        .doc(dto.hostId)
        .set(dto.toModel().toMap(), SetOptions(merge: true));
  }
}
