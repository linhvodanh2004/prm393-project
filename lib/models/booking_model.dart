import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String roomId;
  final String roomTitle;
  final String userId;
  final String userName;
  final String hostId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestCount;
  final double totalPrice;
  // 'pending' | 'confirmed' | 'rejected' | 'paid' | 'completed' | 'cancelled'
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? note;

  // Voucher snapshot (immutable after booking is created)
  final String? voucherId;
  final String? voucherCode;
  final String? voucherScope;   // 'HOST' | 'GLOBAL'
  final String? voucherHostId;
  final double? voucherDiscountAmount;

  BookingModel({
    required this.id,
    required this.roomId,
    required this.roomTitle,
    required this.userId,
    required this.userName,
    required this.hostId,
    required this.checkIn,
    required this.checkOut,
    required this.guestCount,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.voucherId,
    this.voucherCode,
    this.voucherScope,
    this.voucherHostId,
    this.voucherDiscountAmount,
  });

  factory BookingModel.fromMap(Map<String, dynamic> data, String documentId) {
    return BookingModel(
      id: documentId,
      roomId: data['roomId'] ?? '',
      roomTitle: data['roomTitle'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      hostId: data['hostId'] ?? '',
      checkIn: (data['checkIn'] as Timestamp).toDate(),
      checkOut: (data['checkOut'] as Timestamp).toDate(),
      guestCount: data['guestCount'] ?? 1,
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      note: data['note'],
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      voucherId: data['voucherId'],
      voucherCode: data['voucherCode'],
      voucherScope: data['voucherScope'],
      voucherHostId: data['voucherHostId'],
      voucherDiscountAmount:
          (data['voucherDiscountAmount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'roomTitle': roomTitle,
      'userId': userId,
      'userName': userName,
      'hostId': hostId,
      'checkIn': Timestamp.fromDate(checkIn),
      'checkOut': Timestamp.fromDate(checkOut),
      'guestCount': guestCount,
      'totalPrice': totalPrice,
      'status': status,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (voucherId != null) 'voucherId': voucherId,
      if (voucherCode != null) 'voucherCode': voucherCode,
      if (voucherScope != null) 'voucherScope': voucherScope,
      if (voucherHostId != null) 'voucherHostId': voucherHostId,
      if (voucherDiscountAmount != null)
        'voucherDiscountAmount': voucherDiscountAmount,
    };
  }

  BookingModel copyWith({
    String? status,
    String? note,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id,
      roomId: roomId,
      roomTitle: roomTitle,
      userId: userId,
      userName: userName,
      hostId: hostId,
      checkIn: checkIn,
      checkOut: checkOut,
      guestCount: guestCount,
      totalPrice: totalPrice,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      note: note ?? this.note,
      voucherId: voucherId,
      voucherCode: voucherCode,
      voucherScope: voucherScope,
      voucherHostId: voucherHostId,
      voucherDiscountAmount: voucherDiscountAmount,
    );
  }
}
