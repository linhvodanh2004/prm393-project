import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
<<<<<<< HEAD
  final String name;
  final String type;
  final String description;
  final double price;
  final List<String> image;
  final bool isAvailable;

  RoomModel({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.price,
    required this.image,
    required this.isAvailable,
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      image: data['image'] is String
          ? [data['image']] // nếu Firestore lưu 1 URL duy nhất
          : List<String>.from(data['image'] ?? []), // nếu Firestore lưu array
      isAvailable: data['isAvailable'] ?? true,
=======
  final String hostId;
  final String title;
  final String description;
  final List<String> images;
  final double basePrice;
  final String status; // 'available', 'maintenance', 'unavailable'
  final int quantity; // Total rooms of this exact type
  final List<String> amenities; // e.g. ['wifi', 'pool', 'ac', 'tv']
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
>>>>>>> 22bb14d3e32a537dcf429c72349cea5ff39c667b
    );
  }

  Map<String, dynamic> toMap() {
    return {
<<<<<<< HEAD
      'type': type,
      'description': description,
      'price': price,
      'image': image,
      'isAvailable': isAvailable,
=======
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
>>>>>>> 22bb14d3e32a537dcf429c72349cea5ff39c667b
    };
  }

  RoomModel copyWith({
<<<<<<< HEAD
    String? id,
    String? name,
    String? type,
    String? description,
    double? price,
    List<String>? image,
    bool? isAvailable,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      isAvailable: isAvailable ?? this.isAvailable,
=======
    String? title,
    String? description,
    List<String>? images,
    double? basePrice,
    String? status,
    int? quantity,
    List<String>? amenities,
  }) {
    return RoomModel(
      id: id,
      hostId: hostId,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      basePrice: basePrice ?? this.basePrice,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      amenities: amenities ?? this.amenities,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
>>>>>>> 22bb14d3e32a537dcf429c72349cea5ff39c667b
    );
  }
}
