import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
  final String hostId;
  final String title;
  final String description;
  final List<String> images;
  final double basePrice; // Price per hour (VND)
  final String status; // 'available', 'maintenance', 'unavailable'
  final int quantity; // Total units of this room type
  final List<String> amenities;
  final Map<String, dynamic>? location; // Inherited from PropertyModel for Geohash search
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
    this.location,
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
      location: data['location'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    final map = {
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
    if (location != null) {
      map['location'] = location!;
    }
    return map;
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
    Map<String, dynamic>? location,
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
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
