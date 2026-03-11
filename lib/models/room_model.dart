import 'package:cloud_firestore/cloud_firestore.dart';

class RoomModel {
  final String id;
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'description': description,
      'price': price,
      'image': image,
      'isAvailable': isAvailable,
    };
  }

  RoomModel copyWith({
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
    );
  }
}
