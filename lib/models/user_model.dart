import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? address;
  final DateTime? dateOfBirth;
  final String? displayName;
  final String? photoURL;
  final String authProvider;
  final String role;
  final DateTime? createdAt;
  final bool isActive;
  final List<String> favorites;

  UserModel({
    required this.uid,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.address,
    this.dateOfBirth,
    this.displayName,
    this.photoURL,
    required this.authProvider,
    this.role = 'USER',
    this.createdAt,
    this.isActive = true,
    this.favorites = const [],
  });

  // Factory constructor to create UserModel from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'],
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      authProvider: data['authProvider'] ?? 'unknown',
      role: data['role'] ?? 'USER',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      favorites: List<String>.from(data['favorites'] ?? []),
    );
  }

  // Factory constructor to create UserModel from Map
  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      fullName: data['fullName'],
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      authProvider: data['authProvider'] ?? 'unknown',
      role: data['role'] ?? 'USER',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      favorites: List<String>.from(data['favorites'] ?? []),
    );
  }

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      if (fullName != null) 'fullName': fullName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (address != null) 'address': address,
      if (dateOfBirth != null) 'dateOfBirth': Timestamp.fromDate(dateOfBirth!),
      if (displayName != null) 'displayName': displayName,
      if (photoURL != null) 'photoURL': photoURL,
      'authProvider': authProvider,
      'role': role,
      'isActive': isActive,
      'favorites': favorites,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  // Convert UserModel to a JSON string for Local Caching
  String toJson() {
    return jsonEncode({
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'address': address,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'displayName': displayName,
      'photoURL': photoURL,
      'authProvider': authProvider,
      'role': role,
      'isActive': isActive,
      'favorites': favorites,
      'createdAt': createdAt?.toIso8601String(),
    });
  }

  // Create UserModel from a JSON string (Local Cache)
  factory UserModel.fromJson(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'],
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      dateOfBirth: data['dateOfBirth'] != null
          ? DateTime.tryParse(data['dateOfBirth'])
          : null,
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      authProvider: data['authProvider'] ?? 'unknown',
      role: data['role'] ?? 'USER',
      isActive: data['isActive'] ?? true,
      favorites: List<String>.from(data['favorites'] ?? []),
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'])
          : null,
    );
  }

  // Get display name (prefer fullName, fallback to displayName, then email)
  String get name {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    return email;
  }

  // Check if user has complete profile (for email/password users)
  bool get hasCompleteProfile {
    return fullName != null &&
        phoneNumber != null &&
        address != null &&
        dateOfBirth != null;
  }

  // Check if user is Google user
  bool get isGoogleUser => authProvider == 'google';

  // Check if user is email/password user
  bool get isEmailUser => authProvider == 'email';

  // Role checks
  bool get isAdmin => role == 'ADMIN';
  bool get isHost => role == 'HOST';
  bool get isUser => role == 'USER';
}
