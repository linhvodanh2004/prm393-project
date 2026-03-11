import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/property_service.dart';
import '../../models/user_model.dart';
import '../../models/property_model.dart';
import '../../models/host_request_model.dart';
import '../../main.dart';
import '../../widgets/profile/profile_avatar.dart';
import '../../widgets/profile/user_info_card.dart';
import '../../widgets/profile/host_property_card.dart';
import '../../services/host_request_service.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'become_host_screen.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final PropertyService _propertyService = PropertyService();
  final HostRequestService _hostRequestService = HostRequestService();
  final ImagePicker _picker = ImagePicker();

  UserModel? _userData;
  PropertyModel? _propertyData;
  HostRequestModel? _currentHostRequest;
  bool _isLoading = true;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await _authService.getUserData(user.uid);

      PropertyModel? property;
      HostRequestModel? currentRequest;

      if (data != null) {
        if (data.role == 'host') {
          property = await _propertyService.getPropertyByHost(data.uid).first;
        } else if (data.role == 'user') {
          final requests = await _hostRequestService
              .getUserRequests(data.uid)
              .first;
          if (requests.isNotEmpty) {
            currentRequest = requests.first;
          }
        }
      }

      setState(() {
        _userData = data;
        _propertyData = property;
        _currentHostRequest = currentRequest;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // Handle Avatar Selection
  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null || _userData == null) return;

      setState(() => _isUploadingAvatar = true);

      // Explicitly delete the old avatar from Cloudinary first if it exists
      if (_userData!.photoURL != null &&
          _userData!.photoURL!.startsWith('http')) {
        await _storageService.deleteAvatarFromCloudinary(_userData!.photoURL!);
      }

      // Upload to Cloudinary (will overwrite existing avatar because of public_id strategy)
      final String? secureUrl = await _storageService.uploadAvatarToCloudinary(
        _userData!.uid,
        File(image.path),
      );

      if (secureUrl != null) {
        // Update Firestore & Cache
        await _authService.updateAvatarUrl(_userData!.uid, secureUrl);
        await _loadUserData(); // Refresh UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải ảnh: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  // Handle Avatar Deletion
  Future<void> _deleteAvatar() async {
    if (_userData == null || _userData!.photoURL == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      // Delete the actual image asset from Cloudinary
      if (_userData!.photoURL!.startsWith('http')) {
        await _storageService.deleteAvatarFromCloudinary(_userData!.photoURL!);
      }

      // Nullify the Firestore reference
      await _authService.updateAvatarUrl(_userData!.uid, null);
      await _loadUserData(); // Refresh UI
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xóa ảnh: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text(
                'Tải ảnh lên',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadAvatar();
              },
            ),
            if (_userData?.photoURL != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Xóa ảnh hiện tại',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text(
          'Hồ sơ của tôi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
          ? Center(
              child: Text(
                'No user logged in',
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Picture with Edit Badge
                  ProfileAvatar(
                    photoURL: _userData?.photoURL,
                    isUploading: _isUploadingAvatar,
                    onEditTap: _showAvatarOptions,
                  ),
                  const SizedBox(height: 20),

                  // User Info Card
                  if (_userData != null)
                    UserInfoCard(
                      userData: _userData!,
                      fallbackEmail: user.email ?? 'Chưa cập nhật',
                    ),
                  const SizedBox(height: 20),

                  // Host Property Card (If user is host)
                  if (_userData != null && _userData!.role == 'host') ...[
                    HostPropertyCard(
                      property: _propertyData,
                      hostId: _userData!.uid,
                      onDataChanged: _loadUserData,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Profile Status Badge
                  if (_userData != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _userData!.hasCompleteProfile
                            ? Colors.green
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _userData!.hasCompleteProfile
                            ? '✓ Hồ sơ đã hoàn tất'
                            : '⚠ Hồ sơ chưa hoàn tất',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Become a Host Button / Request Status (If user is a normal user)
                  if (_userData != null &&
                      _userData!.role.toUpperCase() == 'USER') ...[
                    if (_currentHostRequest?.status == 'pending')
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4A853).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFD4A853).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFD4A853),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Đang chờ duyệt đăng ký đối tác',
                              style: TextStyle(
                                color: Color(0xFFD4A853),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BecomeHostScreen(
                                  userModel: _userData!,
                                  existingRequest: _currentHostRequest,
                                ),
                              ),
                            );
                            if (result == true) {
                              _loadUserData();
                            }
                          },
                          icon: const Icon(Icons.store, size: 20),
                          label: Text(
                            _currentHostRequest?.status == 'rejected'
                                ? 'Cập nhật đăng ký đối tác'
                                : 'Đăng ký làm đối tác (Host)',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A2A2A),
                            foregroundColor: const Color(0xFFD4A853),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                color: Color(0xFFD4A853),
                                width: 1,
                              ),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],

                  // ACTION BUTTONS
                  if (_userData != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditProfileScreen(userModel: _userData!),
                            ),
                          );
                          if (result == true) {
                            _loadUserData(); // Refresh data after edit
                          }
                        },
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        label: const Text('Chỉnh sửa hồ sơ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4A853),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Disable change password if user is logged in with google
                    if (_userData?.authProvider != 'google') ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChangePasswordScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.lock_reset, size: 20),
                          label: const Text('Đổi mật khẩu'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.2),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _authService.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => AuthWrapper()),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text('Đăng xuất'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF6B6B),
                        side: BorderSide(
                          color: const Color(0xFFFF6B6B).withOpacity(0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
