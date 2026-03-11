import 'package:cloud_firestore/cloud_firestore.dart';

class HostRequestModel {
  final String id;
  final String userId;
  final String businessName;
  final String phone;
  final String citizenId;
  final String address;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final String? note; // e.g reason for rejection by admin

  HostRequestModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.phone,
    required this.citizenId,
    required this.address,
    required this.status,
    required this.createdAt,
    this.note,
  });

  factory HostRequestModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return HostRequestModel(
      id: documentId,
      userId: data['userId'] ?? '',
      businessName: data['businessName'] ?? '',
      phone: data['phone'] ?? '',
      citizenId: data['citizenId'] ?? '',
      address: data['address'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      note: data['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'businessName': businessName,
      'phone': phone,
      'citizenId': citizenId,
      'address': address,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'note': note,
    };
  }

  HostRequestModel copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? phone,
    String? citizenId,
    String? address,
    String? status,
    DateTime? createdAt,
    String? note,
  }) {
    return HostRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      phone: phone ?? this.phone,
      citizenId: citizenId ?? this.citizenId,
      address: address ?? this.address,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }
}
