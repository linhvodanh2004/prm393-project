import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../DTOs/create_notification_dto.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream notifications for the current user
  Stream<List<NotificationModel>> getUserNotifications() {
    final currentId = _auth.currentUser?.uid;
    if (currentId == null) return const Stream.empty();

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: currentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Stream unread count
  Stream<int> getUnreadCount() {
    final currentId = _auth.currentUser?.uid;
    if (currentId == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: currentId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark single notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    final currentId = _auth.currentUser?.uid;
    if (currentId == null) return;

    final batch = _firestore.batch();
    final query = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: currentId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  /// Create a new notification (used by other services).
  /// Accepts a [CreateNotificationDTO] or the named parameters directly for
  /// backward-compatible internal usage.
  Future<void> createNotification({
    required String recipientId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    final dto = CreateNotificationDTO(
      recipientId: recipientId,
      title: title,
      body: body,
      type: type,
      relatedId: relatedId,
    );
    final error = dto.validate();
    if (error != null) throw Exception(error);

    final model = NotificationModel(
      id: '',
      recipientId: dto.recipientId,
      title: dto.title,
      body: dto.body,
      type: dto.type,
      relatedId: dto.relatedId,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('notifications').add(model.toMap());
  }

  /// Create a notification from a pre-built [CreateNotificationDTO].
  Future<void> createNotificationFromDto(CreateNotificationDTO dto) async {
    final error = dto.validate();
    if (error != null) throw Exception(error);

    final model = NotificationModel(
      id: '',
      recipientId: dto.recipientId,
      title: dto.title,
      body: dto.body,
      type: dto.type,
      relatedId: dto.relatedId,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('notifications').add(model.toMap());
  }
}
