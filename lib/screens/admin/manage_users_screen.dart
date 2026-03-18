import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/host_request_model.dart';
import '../../models/property_model.dart';
import '../../DTOs/save_property_dto.dart';
import '../../utils/format_utils.dart';
import '../../widgets/common/admin_stat_card.dart';

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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

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
            content: Text('Đã duyệt yêu cầu trở thành đối tác'),
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

  // ── Popups ────────────────────────────────────────────────────────────────

  void _showUserDetail(UserModel u) {
    Color roleColor;
    String roleLabel;
    switch (u.role.toUpperCase()) {
      case 'ADMIN':
        roleColor = Colors.purple;
        roleLabel = 'Admin';
        break;
      case 'HOST':
        roleColor = const Color(0xFFFFD700);
        roleLabel = 'Đối tác';
        break;
      default:
        roleColor = Colors.blue;
        roleLabel = 'Người dùng';
    }

    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFF2A2A2A),
                backgroundImage:
                    u.photoURL != null && u.photoURL!.isNotEmpty
                        ? NetworkImage(u.photoURL!)
                        : null,
                child: u.photoURL == null || u.photoURL!.isEmpty
                    ? const Icon(Icons.person, color: Colors.white38, size: 36)
                    : null,
              ),
              const SizedBox(height: 12),
              // Name + role badge
              Text(u.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: roleColor.withValues(alpha: 0.4)),
                ),
                child: Text(roleLabel,
                    style: TextStyle(
                        color: roleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              // Info rows
              _infoRow(Icons.email_outlined, u.email),
              if (u.phoneNumber != null && u.phoneNumber!.isNotEmpty)
                _infoRow(Icons.phone_outlined, u.phoneNumber!),
              _infoRow(
                u.isActive ? Icons.check_circle_outline : Icons.lock_outline,
                u.isActive ? 'Đang hoạt động' : 'Đã bị khóa',
                color: u.isActive ? Colors.green : Colors.redAccent,
              ),
              _infoRow(Icons.calendar_today_outlined,
                  'Tham gia: ${FormatUtils.dateVi(u.createdAt ?? DateTime.now())}'),
              const SizedBox(height: 16),
              // Close button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A2A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Đóng',
                      style: TextStyle(color: Colors.white70)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPropertyDetail(UserModel host, PropertyModel prop) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image
              if (prop.coverImage.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    prop.coverImage,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context2, e, st) => Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                          child: Icon(Icons.storefront,
                              color: Colors.white24, size: 40)),
                    ),
                  ),
                )
              else
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                      child: Icon(Icons.storefront,
                          color: Colors.white24, size: 40)),
                ),
              const SizedBox(height: 14),
              Text(prop.title.isNotEmpty ? prop.title : '(Chưa đặt tên)',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _infoRow(Icons.person_outline, 'Đối tác: ${host.name}'),
              _infoRow(Icons.email_outlined, host.email),
              if (prop.address.isNotEmpty)
                _infoRow(Icons.location_on_outlined, prop.address),
              if (prop.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Mô tả',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(prop.description,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13)),
              ],
              if (prop.policies.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Chính sách',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ...prop.policies.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ',
                              style: TextStyle(color: Colors.white38)),
                          Expanded(
                              child: Text(p,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 13))),
                        ],
                      ),
                    )),
              ],
              _infoRow(Icons.calendar_today_outlined,
                  'Tham gia: ${FormatUtils.dateVi(prop.createdAt)}'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A2A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Đóng',
                      style: TextStyle(color: Colors.white70)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color ?? Colors.white38),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: color ?? Colors.white60, fontSize: 13))),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
            Tab(text: 'Đối tác'),
            Tab(text: 'Yêu cầu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserTab(),
          _buildPartnersTab(),
          _buildHostRequestTab(),
        ],
      ),
    );
  }

  // ── Tab: Người dùng ───────────────────────────────────────────────────────

  Widget _buildUserTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').snapshots(),
      builder: (ctx, snap) {
        final allUsers = snap.hasData
            ? snap.data!.docs
                .map((d) =>
                    UserModel.fromMap(d.id, d.data() as Map<String, dynamic>))
                .toList()
            : <UserModel>[];

        final totalUsers = allUsers.length;
        final totalHosts =
            allUsers.where((u) => u.role.toUpperCase() == 'HOST').length;
        final totalLocked = allUsers.where((u) => !u.isActive).length;

        var filtered = allUsers;
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          filtered = allUsers
              .where((u) =>
                  u.name.toLowerCase().contains(q) ||
                  u.email.toLowerCase().contains(q))
              .toList();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  AdminStatCard(icon: Icons.people_rounded, value: '$totalUsers', label: 'Tổng', color: Colors.blue),
                  const SizedBox(width: 8),
                  AdminStatCard(icon: Icons.storefront_rounded, value: '$totalHosts', label: 'Đối tác', color: const Color(0xFFFFD700)),
                  const SizedBox(width: 8),
                  AdminStatCard(icon: Icons.lock_rounded, value: '$totalLocked', label: 'Bị khóa', color: Colors.redAccent),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, email...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon:
                      const Icon(Icons.search, color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: !snap.hasData
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFFFD700)))
                  : filtered.isEmpty
                      ? const Center(
                          child: Text('Không tìm thấy',
                              style: TextStyle(color: Colors.white38)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) =>
                              _buildUserCard(filtered[i]),
                        ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildUserCard(UserModel u) {
    Color roleColor;
    switch (u.role.toUpperCase()) {
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
        onTap: () => _showUserDetail(u),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          icon: const Icon(Icons.more_vert, color: Colors.white38),
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

  // ── Tab: Đối tác ──────────────────────────────────────────────────────────

  Widget _buildPartnersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('users')
          .where('role', isEqualTo: 'HOST')
          .snapshots(),
      builder: (ctx, userSnap) {
        if (!userSnap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)));
        }

        final hosts = userSnap.data!.docs
            .map((d) =>
                UserModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList();

        if (hosts.isEmpty) {
          return const Center(
              child: Text('Chưa có đối tác nào',
                  style: TextStyle(color: Colors.white38)));
        }

        // Stat bar
        final totalHosts = hosts.length;
        final activeHosts = hosts.where((h) => h.isActive).length;
        final lockedHosts = hosts.where((h) => !h.isActive).length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Row(
                children: [
                  AdminStatCard(icon: Icons.storefront_rounded, value: '$totalHosts', label: 'Tổng đối tác', color: const Color(0xFFFFD700)),
                  const SizedBox(width: 8),
                  AdminStatCard(icon: Icons.check_circle_rounded, value: '$activeHosts', label: 'Đang HĐ', color: Colors.green),
                  const SizedBox(width: 8),
                  AdminStatCard(icon: Icons.lock_rounded, value: '$lockedHosts', label: 'Bị khóa', color: Colors.redAccent),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: hosts.length,
                itemBuilder: (_, i) => _buildPartnerCard(hosts[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPartnerCard(UserModel host) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _openPartnerDetail(host),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2A2A2A),
          backgroundImage: host.photoURL != null && host.photoURL!.isNotEmpty
              ? NetworkImage(host.photoURL!)
              : null,
          child: host.photoURL == null || host.photoURL!.isEmpty
              ? const Icon(Icons.storefront, color: Colors.white38)
              : null,
        ),
        title: Text(host.name,
            style: TextStyle(
                color: host.isActive ? Colors.white : Colors.white38,
                fontWeight: FontWeight.w500)),
        subtitle: Text(host.email,
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!host.isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Bị khóa',
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Future<void> _openPartnerDetail(UserModel host) async {
    // Fetch property from Firestore
    final doc = await _db.collection('properties').doc(host.uid).get();
    if (!mounted) return;

    if (!doc.exists || doc.data() == null) {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Chưa có thông tin',
              style: TextStyle(color: Colors.white)),
          content: Text(
              '${host.name} chưa cập nhật thông tin khách sạn.',
              style: const TextStyle(color: Colors.white60)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng')),
          ],
        ),
      );
      return;
    }

    final prop = PropertyModel.fromMap(doc.data()!);
    _showPropertyDetail(host, prop);
  }

  // ── Tab: Yêu cầu hợp tác ─────────────────────────────────────────────────

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
              child: CircularProgressIndicator(color: Color(0xFFFFD700)));
        }
        final requests = snap.data!.docs.map((d) {
          return HostRequestModel.fromMap(
              d.data() as Map<String, dynamic>, d.id);
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
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            Text('Địa chỉ: ${req.address}',
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
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
