import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteService {
  final _db = FirebaseFirestore.instance;

  Future<void> addFavorite(String uid, String roomId) async {
    await _db.collection('users').doc(uid).update({
      'favorites': FieldValue.arrayUnion([roomId]),
    });
  }

  Future<void> removeFavorite(String uid, String roomId) async {
    await _db.collection('users').doc(uid).update({
      'favorites': FieldValue.arrayRemove([roomId]),
    });
  }

  Future<void> toggleFavorite(String uid, String roomId, bool isFavorited) {
    return isFavorited
        ? removeFavorite(uid, roomId)
        : addFavorite(uid, roomId);
  }

  /// Stream the user's favorites list (roomIds)
  Stream<List<String>> streamFavoriteIds(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) =>
            List<String>.from(snap.data()?['favorites'] ?? []));
  }
}
