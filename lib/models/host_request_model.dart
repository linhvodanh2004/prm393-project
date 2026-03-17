import 'package:cloud_firestore/cloud_firestore.dart';

class HostRequestModel {
  final String id;
  final String userId;
  final String businessName;
  final String phone;
  final String address;
  final String description;
  final int businessStartYear;
  final String businessType; // 'private' or 'business'
  final String? taxCode; // required only when businessType == 'business'
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final String? note; // e.g reason for rejection by admin

  HostRequestModel({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.phone,
    required this.address,
    required this.description,
    required this.businessStartYear,
    required this.businessType,
    this.taxCode,
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
      address: data['address'] ?? '',
      description: data['description'] ?? '',
      businessStartYear: data['businessStartYear'] ?? DateTime.now().year,
      businessType: data['businessType'] ?? 'private',
      taxCode: data['taxCode'],
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
      'address': address,
      'description': description,
      'businessStartYear': businessStartYear,
      'businessType': businessType,
      'taxCode': taxCode,
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
    String? address,
    String? description,
    int? businessStartYear,
    String? businessType,
    String? taxCode,
    String? status,
    DateTime? createdAt,
    String? note,
  }) {
    return HostRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      description: description ?? this.description,
      businessStartYear: businessStartYear ?? this.businessStartYear,
      businessType: businessType ?? this.businessType,
      taxCode: taxCode ?? this.taxCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }
}
