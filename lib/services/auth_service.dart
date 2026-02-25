import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../DTOs/register_dto.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print(e.toString());
      // In a real app, you'd want to return or throw specific errors
      return null;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential result = await _auth.signInWithCredential(credential);
      
      // Check if user data exists in Firestore, if not create basic profile
      if (result.user != null) {
        final userDoc = await _firestore.collection('users').doc(result.user!.uid).get();
        if (!userDoc.exists) {
          // Create basic user profile for Google sign-in users
          final userDTO = UserModel(
            uid: result.user!.uid,
            email: result.user!.email ?? '',
            displayName: result.user!.displayName,
            photoURL: result.user!.photoURL,
            authProvider: 'google',
            createdAt: DateTime.now(),
          );
          await _firestore.collection('users').doc(result.user!.uid).set(userDTO.toFirestore());
        }
      }
      
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Register with email/password and additional user data using DTO
  Future<User?> registerWithDetails(RegisterDTO registerDTO) async {
    try {
      // Validate DTO
      final validationError = registerDTO.validate();
      if (validationError != null) {
        print('Validation error: $validationError');
        return null;
      }

      // Create auth account
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: registerDTO.email,
        password: registerDTO.password,
      );

      // Store additional user data in Firestore using DTO
      if (result.user != null) {
        final firestoreData = registerDTO.toFirestore();
        firestoreData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(result.user!.uid).set(firestoreData);
      }

      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Get user data from Firestore as UserModel
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Update user profile in Firestore
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Update user profile error: ${e.toString()}');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
