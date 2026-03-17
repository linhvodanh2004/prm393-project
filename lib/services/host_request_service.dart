import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/host_request_model.dart';
import '../DTOs/submit_host_request_dto.dart';

class HostRequestService {
  final CollectionReference _requestsCollection = FirebaseFirestore.instance
      .collection('host_requests');

  /// Submit a new host request from a [SubmitHostRequestDTO].
  Future<void> submitRequest(SubmitHostRequestDTO dto) async {
    final error = dto.validate();
    if (error != null) throw Exception(error);

    await _requestsCollection.add(dto.toModel().toMap());
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
