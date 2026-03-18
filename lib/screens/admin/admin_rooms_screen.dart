import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/room_model.dart';
import '../../utils/format_utils.dart';
import '../../widgets/common/admin_stat_card.dart';

class AdminRoomsScreen extends StatefulWidget {
  const AdminRoomsScreen({super.key});

  @override
  State<AdminRoomsScreen> createState() => _AdminRoomsScreenState();
}

class _AdminRoomsScreenState extends State<AdminRoomsScreen> {
  final _db = FirebaseFirestore.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _statusFilter = 'ALL';

  final Map<String, String> _hostAddressCache = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Stream<List<RoomModel>> _streamAll() {
    return _db
        .collection('rooms')
        .snapshots()
        .map((s) =>
            s.docs.map((d) => RoomModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> _updateStatus(String roomId, String status,
      {String? reason}) async {
    try {
      await _db.collection('rooms').doc(roomId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        if (reason?.trim().isNotEmpty == true) 'adminNote': reason!.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Đã $status phòng'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _prefetchHostAddress(String hostId) async {
    if (_hostAddressCache.containsKey(hostId)) return;
    try {
      final doc = await _db.collection('properties').doc(hostId).get();
      final address = (doc.data()?['address'] ?? '').toString().trim();
      _hostAddressCache[hostId] = address;
      if (mounted) setState(() {});
    } catch (_) {
      _hostAddressCache[hostId] = '';
    }
  }

  String _addressFor(RoomModel r) => (_hostAddressCache[r.hostId] ?? '').trim();

  bool _matches(RoomModel r) {
    if (_statusFilter != 'ALL' && r.status != _statusFilter) return false;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final title = r.title.toLowerCase();
    final address = _addressFor(r).toLowerCase();
    return title.contains(q) || address.contains(q);
  }

  Future<void> _approveRoom(RoomModel r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title:
            const Text('Duyệt phòng', style: TextStyle(color: Colors.white)),
        content: Text('Duyệt phòng "${r.title}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Duyệt',
                  style: TextStyle(color: Color(0xFFFFD700)))),
        ],
      ),
    );
    if (ok == true) {
      await _updateStatus(r.id, 'available');
    }
  }

  Future<void> _rejectRoom(RoomModel r) async {
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Từ chối phòng',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Từ chối phòng "${r.title}"?',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Lý do (tùy chọn)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
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
    if (ok == true) {
      await _updateStatus(r.id, 'unavailable', reason: noteCtrl.text.trim());
    }
  }

  Future<void> _showRoomDetail(RoomModel r) async {
    final address = _addressFor(r);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(r.title, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (address.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.white38),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(address,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Text('Giá: ${FormatUtils.vnd(r.basePrice)} / giờ',
                  style: const TextStyle(
                      color: Color(0xFFFFD700), fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Trạng thái: ${r.status}',
                  style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 10),
              if (r.description.isNotEmpty)
                Text(r.description,
                    style: const TextStyle(color: Colors.white70, height: 1.4)),
              if (r.amenities.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: r.amenities
                      .map((a) => Chip(
                            label: Text(a,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.white70)),
                            backgroundColor: const Color(0xFF2A2A2A),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: Colors.white70)),
          ),
          if (r.status == 'pending_review') ...[
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _rejectRoom(r);
              },
              child: const Text('Từ chối',
                  style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _approveRoom(r);
              },
              child:
                  const Text('Duyệt', style: TextStyle(color: Color(0xFFFFD700))),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Quản lý phòng',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<RoomModel>>(
        stream: _streamAll(),
        builder: (ctx, snap) {
          final allRooms = snap.data ?? [];
          for (final r in allRooms) {
            _prefetchHostAddress(r.hostId);
          }

          final totalRooms = allRooms.length;
          final availableCount =
              allRooms.where((r) => r.status == 'available').length;
          final pendingCount =
              allRooms.where((r) => r.status == 'pending_review').length;
          final maintenanceCount =
              allRooms.where((r) => r.status == 'maintenance').length;
          final unavailableCount =
              allRooms.where((r) => r.status == 'unavailable').length;

          final filtered = allRooms.where(_matches).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return Column(
            children: [
              // ── Stat row ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(
                  children: [
                    AdminStatCard(icon: Icons.meeting_room_rounded, value: '$totalRooms', label: 'Tổng', color: Colors.blue),
                    const SizedBox(width: 6),
                    AdminStatCard(icon: Icons.check_circle_rounded, value: '$availableCount', label: 'Khả dụng', color: Colors.green),
                    const SizedBox(width: 6),
                    AdminStatCard(icon: Icons.pending_rounded, value: '$pendingCount', label: 'Chờ duyệt', color: Colors.orange),
                    const SizedBox(width: 6),
                    AdminStatCard(icon: Icons.block_rounded, value: '${maintenanceCount + unavailableCount}', label: 'Không KD', color: Colors.redAccent),
                  ],
                ),
              ),
              // ── Search ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tiêu đề hoặc địa chỉ...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.white54),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  children: [
                    _statusChip('ALL', 'Tất cả'),
                    _statusChip('pending_review', 'Chờ duyệt'),
                    _statusChip('available', 'Khả dụng'),
                    _statusChip('maintenance', 'Bảo trì'),
                    _statusChip('unavailable', 'Không khả dụng'),
                  ],
                ),
              ),
              // ── List ──────────────────────────────────────────────
              Expanded(
                child: !snap.hasData
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFFFD700)))
                    : snap.hasError
                        ? Center(
                            child: Text('Lỗi: ${snap.error}',
                                style: const TextStyle(
                                    color: Colors.redAccent)))
                        : filtered.isEmpty
                            ? const Center(
                                child: Text('Không có phòng phù hợp',
                                    style: TextStyle(
                                        color: Colors.white38)))
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final r = filtered[i];
                    final addr = _addressFor(r);
                    return Card(
                      color: const Color(0xFF1A1A1A),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        onTap: () => _showRoomDetail(r),
                        contentPadding: const EdgeInsets.all(12),
                        leading: r.images.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  r.images.first,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.meeting_room,
                                          color: Colors.white24),
                                ),
                              )
                            : const Icon(Icons.meeting_room,
                                color: Colors.white24),
                        title: Text(
                          r.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (addr.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 14, color: Colors.white38),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      addr,
                                      style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text('${FormatUtils.vnd(r.basePrice)} / giờ',
                                style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 12)),
                          ],
                        ),
                        trailing: _statusBadge(r.status),
                      ),
                    );
                                },
                              ),
              ),
            ],
          );
        },
      ),
    );
  }



  Widget _statusChip(String value, String label) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white70,
            fontSize: 12,
          ),
        ),
        selected: selected,
        selectedColor: const Color(0xFFFFD700),
        backgroundColor: const Color(0xFF1A1A1A),
        checkmarkColor: Colors.black,
        onSelected: (_) => setState(() => _statusFilter = value),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color c;
    String t;
    switch (status) {
      case 'pending_review':
        c = Colors.orange;
        t = 'Chờ duyệt';
        break;
      case 'available':
        c = Colors.green;
        t = 'Khả dụng';
        break;
      case 'maintenance':
        c = Colors.blueGrey;
        t = 'Bảo trì';
        break;
      case 'unavailable':
      default:
        c = Colors.redAccent;
        t = 'Không khả dụng';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Text(
        t,
        style: TextStyle(
          color: c,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
