import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String userId;
  final String? employeeId;
  final DateTime? timeUsed;
  final String roomId;
  final bool isDone;
  final DateTime createAt;
  final bool isDeleted;
  final String paymentMethod;

  OrderModel({
    required this.id,
    required this.userId,
    this.employeeId,
    this.timeUsed,
    required this.roomId,
    required this.isDone,
    required this.createAt,
    required this.isDeleted,
    required this.paymentMethod,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      employeeId: data['employeeId'] ?? '',
      timeUsed: (data['timeUsed'] as Timestamp).toDate(),
      roomId: data['roomId'] ?? '',
      isDone: data['isDone'] ?? false,
      createAt: (data['createAt'] as Timestamp).toDate(),
      isDeleted: data['isDeleted'] ?? false,
      paymentMethod: data['paymentMethod'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'employeeId': employeeId,
      'timeUsed': timeUsed,
      'roomId': roomId,
      'isDone': isDone,
      'createAt': createAt,
      'isDeleted': isDeleted,
      'paymentMethod': paymentMethod,
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? employeeId,
    DateTime? timeUsed,
    String? roomId,
    bool? isDone,
    DateTime? createAt,
    bool? isDeleted,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      employeeId: employeeId ?? this.employeeId,
      timeUsed: timeUsed ?? this.timeUsed,
      roomId: roomId ?? this.roomId,
      isDone: isDone ?? this.isDone,
      createAt: createAt ?? this.createAt,
      isDeleted: isDeleted ?? this.isDeleted,
      paymentMethod: paymentMethod,
    );
  }
}
