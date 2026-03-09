import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String recipientId;
  final String title;
  final String body;
  final String type; // e.g., 'booking', 'host_request', 'chat'
  final String? relatedId; // e.g., bookingId or roomId
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return NotificationModel(
      id: documentId,
      recipientId: data['recipientId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'system',
      relatedId: data['relatedId'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
