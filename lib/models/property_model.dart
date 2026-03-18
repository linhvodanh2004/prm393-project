import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyModel {
  final String hostId;
  final String title;
  final String description;
  final String address;
  final String coverImage;
  final List<String> policies;
  final Map<String, dynamic>? location; // For geoflutterfire_plus
  final DateTime createdAt;
  final DateTime updatedAt;

  PropertyModel({
    required this.hostId,
    required this.title,
    required this.description,
    required this.address,
    required this.coverImage,
    required this.policies,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PropertyModel.fromMap(Map<String, dynamic> data) {
    return PropertyModel(
      hostId: data['hostId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      coverImage: data['coverImage'] ?? '',
      policies: List<String>.from(data['policies'] ?? []),
      location: data['location'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'hostId': hostId,
      'title': title,
      'description': description,
      'address': address,
      'coverImage': coverImage,
      'policies': policies,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
    if (location != null) {
      map['location'] = location!;
    }
    return map;
  }

  PropertyModel copyWith({
    String? title,
    String? description,
    String? address,
    String? coverImage,
    List<String>? policies,
    Map<String, dynamic>? location,
  }) {
    return PropertyModel(
      hostId: hostId,
      title: title ?? this.title,
      description: description ?? this.description,
      address: address ?? this.address,
      coverImage: coverImage ?? this.coverImage,
      policies: policies ?? this.policies,
      location: location ?? this.location,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
