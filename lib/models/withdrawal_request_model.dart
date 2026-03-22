import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawalRequestModel {
  final String id;
  final String hostId;
  final double amount;
  final String bankCode;
  final String bankAccount;
  final String accountName;
  // 'pending' | 'approved' | 'rejected'
  final String status;
  final String? rejectionReason;
  final String type; // 'withdrawal' | 'refund'
  final String? bookingId;
  final DateTime createdAt;
  final DateTime updatedAt;

  WithdrawalRequestModel({
    required this.id,
    required this.hostId,
    required this.amount,
    required this.bankCode,
    required this.bankAccount,
    required this.accountName,
    required this.status,
    this.rejectionReason,
    this.type = 'withdrawal',
    this.bookingId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WithdrawalRequestModel.fromMap(Map<String, dynamic> data, String documentId) {
    return WithdrawalRequestModel(
      id: documentId,
      hostId: data['hostId'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      bankCode: data['bankCode'] ?? '',
      bankAccount: data['bankAccount'] ?? '',
      accountName: data['accountName'] ?? '',
      status: data['status'] ?? 'pending',
      rejectionReason: data['rejectionReason'],
      type: data['type'] ?? 'withdrawal',
      bookingId: data['bookingId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'amount': amount,
      'bankCode': bankCode,
      'bankAccount': bankAccount,
      'accountName': accountName,
      'status': status,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'type': type,
      if (bookingId != null) 'bookingId': bookingId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
