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
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
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
