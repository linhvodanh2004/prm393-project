import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';
import '../../main.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  UserModel? _userData;
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
      setState(() {
        _userData = data;
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
      // With Cloudinary, we just nullify the Firestore reference
      // (Advanced cleanup would call a Signed Destroy API on the backend)
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
                  Stack(
                    children: [
                      _isUploadingAvatar
                          ? const CircleAvatar(
                              radius: 50,
                              backgroundColor: Color(0xFF1A1A1A),
                              child: CircularProgressIndicator(
                                color: Color(0xFFD4A853),
                              ),
                            )
                          : CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFF2A2A2A),
                              backgroundImage: _userData?.photoURL != null
                                  ? NetworkImage(_userData!.photoURL!)
                                  : null,
                              child: _userData?.photoURL == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white54,
                                    )
                                  : null,
                            ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingAvatar ? null : _showAvatarOptions,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4A853),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF0D0D0D),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // User Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông tin tài khoản',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 16),

                        // Email
                        _buildInfoRow(
                          Icons.email,
                          'Email',
                          _userData?.email ?? user.email ?? 'Chưa cập nhật',
                        ),
                        const SizedBox(height: 12),

                        // Auth Provider
                        _buildInfoRow(
                          Icons.security,
                          'Phương thức đăng nhập',
                          _userData?.authProvider ?? 'Không xác định',
                        ),
                        const SizedBox(height: 12),

                        // Full Name (for email/password users)
                        if (_userData?.fullName != null) ...[
                          _buildInfoRow(
                            Icons.person,
                            'Họ và tên',
                            _userData!.fullName!,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Phone Number
                        if (_userData?.phoneNumber != null) ...[
                          _buildInfoRow(
                            Icons.phone,
                            'Số điện thoại',
                            _userData!.phoneNumber!,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Address
                        if (_userData?.address != null) ...[
                          _buildInfoRow(
                            Icons.home,
                            'Địa chỉ',
                            _userData!.address!,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Date of Birth
                        if (_userData?.dateOfBirth != null) ...[
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Ngày sinh (DD/MM/YYYY)',
                            "${_userData!.dateOfBirth!.day.toString().padLeft(2, '0')}/${_userData!.dateOfBirth!.month.toString().padLeft(2, '0')}/${_userData!.dateOfBirth!.year}",
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFD4A853).withOpacity(0.8)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
