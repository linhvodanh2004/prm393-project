import 'package:cloud_firestore/cloud_firestore.dart';

class VoucherModel {
  final String id;
  final String code;

  // 'HOST' | 'GLOBAL'
  final String scope;
  // Non-null only when scope == 'HOST'
  final String? hostId;

  // 'PERCENT' | 'FIXED'
  final String type;
  final double value;
  final double? maxDiscount;
  final double minSubtotal;

  final DateTime? startAt;
  final DateTime? endAt;
  final bool isActive;

  final int usageLimitTotal;
  final int usageLimitPerUser;

  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  VoucherModel({
    required this.id,
    required this.code,
    required this.scope,
    this.hostId,
    required this.type,
    required this.value,
    this.maxDiscount,
    this.minSubtotal = 0,
    this.startAt,
    this.endAt,
    this.isActive = true,
    this.usageLimitTotal = 9999,
    this.usageLimitPerUser = 1,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VoucherModel.fromMap(Map<String, dynamic> data, String documentId) {
    return VoucherModel(
      id: documentId,
      code: data['code'] ?? '',
      scope: data['scope'] ?? 'GLOBAL',
      hostId: data['hostId'],
      type: data['type'] ?? 'FIXED',
      value: (data['value'] as num?)?.toDouble() ?? 0,
      maxDiscount: (data['maxDiscount'] as num?)?.toDouble(),
      minSubtotal: (data['minSubtotal'] as num?)?.toDouble() ?? 0,
      startAt: (data['startAt'] as Timestamp?)?.toDate(),
      endAt: (data['endAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      usageLimitTotal: data['usageLimitTotal'] ?? 9999,
      usageLimitPerUser: data['usageLimitPerUser'] ?? 1,
      createdBy: data['createdBy'] ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory VoucherModel.fromFirestore(DocumentSnapshot doc) {
    return VoucherModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'scope': scope,
      if (hostId != null) 'hostId': hostId,
      'type': type,
      'value': value,
      if (maxDiscount != null) 'maxDiscount': maxDiscount,
      'minSubtotal': minSubtotal,
      if (startAt != null) 'startAt': Timestamp.fromDate(startAt!),
      if (endAt != null) 'endAt': Timestamp.fromDate(endAt!),
      'isActive': isActive,
      'usageLimitTotal': usageLimitTotal,
      'usageLimitPerUser': usageLimitPerUser,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  VoucherModel copyWith({bool? isActive, DateTime? updatedAt}) {
    return VoucherModel(
      id: id,
      code: code,
      scope: scope,
      hostId: hostId,
      type: type,
      value: value,
      maxDiscount: maxDiscount,
      minSubtotal: minSubtotal,
      startAt: startAt,
      endAt: endAt,
      isActive: isActive ?? this.isActive,
      usageLimitTotal: usageLimitTotal,
      usageLimitPerUser: usageLimitPerUser,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Compute the discount amount for a given subtotal (does NOT enforce usage limits).
  double calculateDiscount(double subtotal) {
    if (!isValid) return 0;
    double discount;
    if (type == 'PERCENT') {
      discount = subtotal * value / 100;
      if (maxDiscount != null) discount = discount.clamp(0, maxDiscount!);
    } else {
      discount = value;
    }
    return discount.clamp(0, subtotal);
  }

  /// True if the voucher is within its validity window and active.
  bool get isValid {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startAt != null && now.isBefore(startAt!)) return false;
    if (endAt != null && now.isAfter(endAt!)) return false;
    return true;
  }
}
