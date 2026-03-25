import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../DTOs/register_dto.dart';
import 'fcm_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '81346965660-ji0vk2p9ier226nomr07rso9rltjgrcv.apps.googleusercontent.com',
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _localUserKey = 'cached_user_model';

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- LOCAL CACHING ---
  Future<void> saveUserLocally(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localUserKey, user.toJson());
  }

  Future<void> clearLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localUserKey);
  }

  Future<UserModel?> getLocalUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_localUserKey);
    if (userJson != null) {
      try {
        return UserModel.fromJson(userJson);
      } catch (_) {
        // Corrupted cache — ignore and return null (will re-fetch from Firestore)
        return null;
      }
    }
    return null;
  }
  // ----------------------

  // ─── Firebase error → Vietnamese message ─────────────────────────────────
  static String _firebaseErrorVi(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không chính xác.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng thử lại sau vài phút.';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được kích hoạt.';
      case 'user-token-expired':
      case 'requires-recent-login':
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng cho tài khoản khác.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng dùng ít nhất 6 ký tự.';
      case 'network-request-failed':
        return 'Không có kết nối mạng. Kiểm tra Wi-Fi hoặc dữ liệu di động.';
      default:
        return e.message ?? 'Xảy ra lỗi không xác định. Vui lòng thử lại.';
    }
  }

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        final userModel = await getUserData(result.user!.uid);
        if (userModel != null && !userModel.isActive) {
          await signOut();
          throw Exception('Tài khoản của bạn đã bị khóa.');
        }
        if (userModel != null) await saveUserLocally(userModel);
        await FcmService().saveTokenAfterLogin(result.user!.uid);
      }
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_firebaseErrorVi(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Đăng nhập thất bại. Vui lòng thử lại.');
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Change password while signed in
  Future<String?> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return "Không tìm thấy phiên đăng nhập";

      // 1. Re-authenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // 2. Change password
      await user.updatePassword(newPassword);
      return null; // Return null on success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Mật khẩu hiện tại không đúng.';
      } else if (e.code == 'weak-password') {
        return 'Mật khẩu mới quá yếu. Dùng ít nhất 6 ký tự.';
      } else if (e.code == 'requires-recent-login') {
        return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng xuất và đăng nhập lại.';
      }
      return _firebaseErrorVi(e);
    } catch (e) {
      return "Đã xảy ra lỗi: ${e.toString()}";
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
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential result = await _auth.signInWithCredential(credential);

      // Check if user data exists in Firestore, if not create basic profile
      if (result.user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .get();
        if (!userDoc.exists) {
          final userDTO = UserModel(
            uid: result.user!.uid,
            email: result.user!.email ?? '',
            displayName: result.user!.displayName,
            photoURL: result.user!.photoURL,
            authProvider: 'google',
            createdAt: DateTime.now(),
          );
          await _firestore
              .collection('users')
              .doc(result.user!.uid)
              .set(userDTO.toFirestore());
        } else {
          final userModel = UserModel.fromFirestore(userDoc);
          if (!userModel.isActive) {
            await signOut();
            throw Exception('Tài khoản của bạn đã bị khóa');
          }
          await saveUserLocally(userModel);
        }
        await FcmService().saveTokenAfterLogin(result.user!.uid);
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_firebaseErrorVi(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Đăng nhập Google thất bại. Vui lòng thử lại.');
    }
  }

  // Register with email/password and additional user data using DTO
  Future<User?> registerWithDetails(RegisterDTO registerDTO) async {
    try {
      final validationError = registerDTO.validate();
      if (validationError != null) {
        throw Exception(validationError);
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
        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(firestoreData);

        final userModel = await getUserData(result.user!.uid);
        if (userModel != null) {
          await saveUserLocally(userModel);
        }
        await FcmService().saveTokenAfterLogin(result.user!.uid);
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_firebaseErrorVi(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Đăng ký thất bại. Vui lòng thử lại.');
    }
  }

  // Get user data from Firestore as UserModel
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    } catch (_) {
      return null;
    }
  }

  // Update user profile in Firestore
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));
      final updatedUser = await getUserData(uid);
      if (updatedUser != null) await saveUserLocally(updatedUser);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Update avatar URL specifically (pass the remote Cloudinary URL)
  Future<bool> updateAvatarUrl(String uid, String? photoUrl) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'photoURL': photoUrl,
      }, SetOptions(merge: true));
      final updatedUser = await getUserData(uid);
      if (updatedUser != null) await saveUserLocally(updatedUser);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await clearLocalUser();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
