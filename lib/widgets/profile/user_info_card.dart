import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'package:intl/intl.dart';

class UserInfoCard extends StatelessWidget {
  final UserModel userData;
  final String fallbackEmail;

  const UserInfoCard({
    Key? key,
    required this.userData,
    required this.fallbackEmail,
  }) : super(key: key);

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
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
          _buildInfoRow(Icons.email, 'Email', userData.email ?? fallbackEmail),
          const SizedBox(height: 12),

          // Auth Provider
          _buildInfoRow(
            Icons.security,
            'Phương thức đăng nhập',
            userData.authProvider,
          ),
          const SizedBox(height: 12),

          // Role (To distinguish Host)
          _buildInfoRow(
            Icons.badge,
            'Loại tài khoản',
            userData.role.toUpperCase(),
          ),
          const SizedBox(height: 12),

          // Full Name
          if (userData.fullName != null) ...[
            _buildInfoRow(Icons.person, 'Họ và tên', userData.fullName!),
            const SizedBox(height: 12),
          ],

          // Phone Number
          if (userData.phoneNumber != null) ...[
            _buildInfoRow(Icons.phone, 'Số điện thoại', userData.phoneNumber!),
            const SizedBox(height: 12),
          ],

          // Address
          if (userData.address != null) ...[
            _buildInfoRow(Icons.home, 'Địa chỉ', userData.address!),
            const SizedBox(height: 12),
          ],

          // Date of Birth
          if (userData.dateOfBirth != null) ...[
            _buildInfoRow(
              Icons.calendar_today,
              'Ngày sinh',
              DateFormat('dd/MM/yyyy').format(userData.dateOfBirth!),
            ),
          ],
        ],
      ),
    );
  }
}
