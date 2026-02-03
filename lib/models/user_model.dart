import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? address;
  final int? age;
  final String? bio;
  final String? displayName;
  final String? photoURL;
  final String authProvider;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.address,
    this.age,
    this.bio,
    this.displayName,
    this.photoURL,
    required this.authProvider,
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
      age: data['age'],
      bio: data['bio'],
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      authProvider: data['authProvider'] ?? 'unknown',
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
      age: data['age'],
      bio: data['bio'],
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      authProvider: data['authProvider'] ?? 'unknown',
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
      if (age != null) 'age': age,
      if (bio != null) 'bio': bio,
      if (displayName != null) 'displayName': displayName,
      if (photoURL != null) 'photoURL': photoURL,
      'authProvider': authProvider,
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
        age != null &&
        bio != null;
  }

  // Check if user is Google user
  bool get isGoogleUser => authProvider == 'google';

  // Check if user is email/password user
  bool get isEmailUser => authProvider == 'email';
}
