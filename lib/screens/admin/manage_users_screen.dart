import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/host_request_model.dart';
import '../../DTOs/save_property_dto.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _setUserActive(String uid, bool active) async {
    await _db.collection('users').doc(uid).update({'isActive': active});
  }

  Future<void> _setUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({'role': role});
  }

  Future<void> _approveHostRequest(HostRequestModel req) async {
    final batch = _db.batch();
    batch.update(_db.collection('host_requests').doc(req.id),
        {'status': 'approved', 'updatedAt': FieldValue.serverTimestamp()});
    batch.update(_db.collection('users').doc(req.userId), {'role': 'HOST'});

    // Map host request → hotel/property info
    final propertyDto = SavePropertyDTO(
      hostId: req.userId,
      title: req.businessName,
      description: req.description,
      address: req.address,
    );
    batch.set(
      _db.collection('properties').doc(req.userId),
      propertyDto.toModel().toMap(),
      SetOptions(merge: true),
    );

    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Đã duyệt yêu cầu trở thành Host'),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _rejectHostRequest(HostRequestModel req) async {
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Từ chối yêu cầu',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: noteCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Lý do từ chối...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Từ chối',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true) return;
    await _db.collection('host_requests').doc(req.id).update({
      'status': 'rejected',
      'note': noteCtrl.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Đã từ chối yêu cầu'),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Quản lý người dùng',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          labelColor: const Color(0xFFFFD700),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Người dùng'),
            Tab(text: 'Yêu cầu Host'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildUserTab(), _buildHostRequestTab()],
      ),
    );
  }

  Widget _buildUserTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, email...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('users').snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFFFD700)));
              }
              var users = snap.data!.docs.map((d) {
                return UserModel.fromMap(
                    d.id, d.data() as Map<String, dynamic>);
              }).toList();

              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                users = users
                    .where((u) =>
                        u.name.toLowerCase().contains(q) ||
                        u.email.toLowerCase().contains(q))
                    .toList();
              }

              if (users.isEmpty) {
                return const Center(
                    child: Text('Không tìm thấy',
                        style: TextStyle(color: Colors.white38)));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: users.length,
                itemBuilder: (_, i) => _buildUserCard(users[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserModel u) {
    Color roleColor;
    switch (u.role) {
      case 'ADMIN':
        roleColor = Colors.purple;
        break;
      case 'HOST':
        roleColor = const Color(0xFFFFD700);
        break;
      default:
        roleColor = Colors.blue;
    }

    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2A2A2A),
          backgroundImage: u.photoURL != null && u.photoURL!.isNotEmpty
              ? NetworkImage(u.photoURL!)
              : null,
          child: u.photoURL == null || u.photoURL!.isEmpty
              ? const Icon(Icons.person, color: Colors.white38)
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(u.name,
                  style: TextStyle(
                      color: u.isActive ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.w500)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(u.role,
                  style: TextStyle(
                      color: roleColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        subtitle: Text(u.email,
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: PopupMenuButton<String>(
          color: const Color(0xFF1A1A1A),
          icon:
              const Icon(Icons.more_vert, color: Colors.white38),
          onSelected: (v) async {
            switch (v) {
              case 'ban':
                await _setUserActive(u.uid, false);
                break;
              case 'unban':
                await _setUserActive(u.uid, true);
                break;
              case 'promote_host':
                await _setUserRole(u.uid, 'HOST');
                break;
              case 'demote_user':
                await _setUserRole(u.uid, 'USER');
                break;
            }
          },
          itemBuilder: (_) => [
            if (u.isActive)
              const PopupMenuItem(
                  value: 'ban',
                  child: Text('Khóa tài khoản',
                      style: TextStyle(color: Colors.redAccent)))
            else
              const PopupMenuItem(
                  value: 'unban',
                  child: Text('Mở khóa',
                      style: TextStyle(color: Colors.green))),
            if (u.role == 'USER')
              const PopupMenuItem(
                  value: 'promote_host',
                  child: Text('Nâng lên HOST',
                      style: TextStyle(color: Color(0xFFFFD700)))),
            if (u.role == 'HOST')
              const PopupMenuItem(
                  value: 'demote_user',
                  child: Text('Hạ xuống USER',
                      style: TextStyle(color: Colors.orange))),
          ],
        ),
      ),
    );
  }

  Widget _buildHostRequestTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('host_requests')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFFFFD700)));
        }
        final requests = snap.data!.docs.map((d) {
          return HostRequestModel.fromMap(d.data() as Map<String, dynamic>, d.id);
        }).toList();

        if (requests.isEmpty) {
          return const Center(
              child: Text('Không có yêu cầu nào đang chờ',
                  style: TextStyle(color: Colors.white38)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          itemBuilder: (_, i) => _buildRequestCard(requests[i]),
        );
      },
    );
  }

  Widget _buildRequestCard(HostRequestModel req) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(req.businessName,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              'Loại hình: ${req.businessType == 'business' ? 'Doanh nghiệp' : 'Cá nhân'}',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            Text(
              'Năm bắt đầu: ${req.businessStartYear}',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            if (req.taxCode != null && req.taxCode!.isNotEmpty)
              Text(
                'MST: ${req.taxCode}',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            Text('SĐT: ${req.phone}',
                style:
                    const TextStyle(color: Colors.white54, fontSize: 13)),
            Text('Địa chỉ: ${req.address}',
                style:
                    const TextStyle(color: Colors.white54, fontSize: 13)),
            if (req.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                req.description,
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectHostRequest(req),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveHostRequest(req),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Phê duyệt'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
