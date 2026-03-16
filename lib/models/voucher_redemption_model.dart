import 'package:cloud_firestore/cloud_firestore.dart';

class VoucherRedemptionModel {
  final String id;
  final String voucherId;
  final String userId;
  final String bookingId;
  final DateTime createdAt;

  VoucherRedemptionModel({
    required this.id,
    required this.voucherId,
    required this.userId,
    required this.bookingId,
    required this.createdAt,
  });

  factory VoucherRedemptionModel.fromMap(
      Map<String, dynamic> data, String documentId) {
    return VoucherRedemptionModel(
      id: documentId,
      voucherId: data['voucherId'] ?? '',
      userId: data['userId'] ?? '',
      bookingId: data['bookingId'] ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'voucherId': voucherId,
      'userId': userId,
      'bookingId': bookingId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
