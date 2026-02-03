import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final AuthService _authService = AuthService();
  UserModel? _userData;
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              // Navigation will be handled by AuthWrapper
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text('No user logged in'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Picture
                      if (_userData?.photoURL != null)
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(_userData!.photoURL!),
                        )
                      else
                        const CircleAvatar(
                          radius: 50,
                          child: Icon(Icons.person, size: 50),
                        ),
                      const SizedBox(height: 20),

                      // User Info Card
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Account Information',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              const SizedBox(height: 10),

                              // Email
                              _buildInfoRow(
                                Icons.email,
                                'Email',
                                _userData?.email ?? user.email ?? 'Not available',
                              ),
                              const SizedBox(height: 12),

                              // Auth Provider
                              _buildInfoRow(
                                Icons.security,
                                'Auth Provider',
                                _userData?.authProvider ?? 'Unknown',
                              ),
                              const SizedBox(height: 12),

                              // Display Name (for Google users)
                              if (_userData?.displayName != null) ...[
                                _buildInfoRow(
                                  Icons.badge,
                                  'Display Name',
                                  _userData!.displayName!,
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Full Name (for email/password users)
                              if (_userData?.fullName != null) ...[
                                _buildInfoRow(
                                  Icons.person,
                                  'Full Name',
                                  _userData!.fullName!,
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Phone Number
                              if (_userData?.phoneNumber != null) ...[
                                _buildInfoRow(
                                  Icons.phone,
                                  'Phone',
                                  _userData!.phoneNumber!,
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Address
                              if (_userData?.address != null) ...[
                                _buildInfoRow(
                                  Icons.home,
                                  'Address',
                                  _userData!.address!,
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Age
                              if (_userData?.age != null) ...[
                                _buildInfoRow(
                                  Icons.cake,
                                  'Age',
                                  _userData!.age.toString(),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Bio
                              if (_userData?.bio != null) ...[
                                _buildInfoRow(
                                  Icons.info,
                                  'Bio',
                                  _userData!.bio!,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Profile Status Badge
                      if (_userData != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _userData!.hasCompleteProfile ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _userData!.hasCompleteProfile
                                ? '✓ Complete Profile'
                                : '⚠ Incomplete Profile',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Logout Button
                      ElevatedButton.icon(
                        onPressed: () async {
                          await _authService.signOut();
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
