import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
  final String hostId;
  final String title;
  final String description;
  final List<String> images;
  final double basePrice;
  // 'available' | 'maintenance' | 'unavailable' | 'pending_review'
  final String status;
  final int quantity;
  final List<String> amenities;
  final DateTime createdAt;
  final DateTime updatedAt;

  RoomModel({
    required this.id,
    required this.hostId,
    required this.title,
    required this.description,
    required this.images,
    required this.basePrice,
    required this.status,
    required this.quantity,
    required this.amenities,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoomModel.fromMap(Map<String, dynamic> data, String documentId) {
    return RoomModel(
      id: documentId,
      hostId: data['hostId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      basePrice: (data['basePrice'] ?? 0).toDouble(),
      status: data['status'] ?? 'available',
      quantity: data['quantity'] ?? 1,
      amenities: List<String>.from(data['amenities'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'title': title,
      'description': description,
      'images': images,
      'basePrice': basePrice,
      'status': status,
      'quantity': quantity,
      'amenities': amenities,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  RoomModel copyWith({
    String? id,
    String? hostId,
    String? title,
    String? description,
    List<String>? images,
    double? basePrice,
    String? status,
    int? quantity,
    List<String>? amenities,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      basePrice: basePrice ?? this.basePrice,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      amenities: amenities ?? this.amenities,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
