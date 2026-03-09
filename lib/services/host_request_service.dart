import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/host_request_model.dart';

class HostRequestService {
  final CollectionReference _requestsCollection = FirebaseFirestore.instance
      .collection('host_requests');

  /// Submit a new host request
  Future<void> submitRequest(HostRequestModel request) async {
    // Before submitting a new request, ensure the user does not already have a pending/approved request.
    // That should be checked via UI, but it's good to recheck conceptually.

    // We add a new document, the ID is auto-generated
    await _requestsCollection.add(request.toMap());
  }

  /// Update an existing request (for when admin rejects, and user resubmits)
  Future<void> updateRequest(HostRequestModel request) async {
    await _requestsCollection.doc(request.id).update(request.toMap());
  }

  /// Get the active host request for a user (if any)
  /// Active means pending or rejected. If approved, they are a host.
  /// Sorting by createdAt descending to get the latest request.
  Stream<List<HostRequestModel>> getUserRequests(String userId) {
    return _requestsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => HostRequestModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }
}
