import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String roomId;
  final String roomTitle; // Snapshot for easy listing
  final String userId;
  final String userName; // Snapshot
  final String hostId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestCount;
  final double totalPrice;
  final String
  status; // 'pending', 'confirmed', 'rejected', 'paid', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? note;

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
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
    };
  }
}
