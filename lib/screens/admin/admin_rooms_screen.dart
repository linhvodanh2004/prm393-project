import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/room_model.dart';
import '../../utils/format_utils.dart';

class AdminRoomsScreen extends StatefulWidget {
  const AdminRoomsScreen({super.key});

  @override
  State<AdminRoomsScreen> createState() => _AdminRoomsScreenState();
}

class _AdminRoomsScreenState extends State<AdminRoomsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<RoomModel>> _streamByStatus(String status) {
    return _db
        .collection('rooms')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => RoomModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> _updateStatus(String roomId, String status, {String? reason}) async {
    try {
      await _db.collection('rooms').doc(roomId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        if (reason != null) 'adminNote': reason,
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

  Widget _buildRoomList(Stream<List<RoomModel>> stream,
      {bool showActions = false}) {
    return StreamBuilder<List<RoomModel>>(
      stream: stream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)));
        }
        if (snap.hasError) {
          return Center(
              child: Text('Lỗi: ${snap.error}',
                  style: const TextStyle(color: Colors.red)));
        }
        final rooms = snap.data ?? [];
        if (rooms.isEmpty) {
          return const Center(
              child: Text('Không có phòng',
                  style: TextStyle(color: Colors.white38)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rooms.length,
          itemBuilder: (_, i) {
            final r = rooms[i];
            return Card(
              color: const Color(0xFF1A1A1A),
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: r.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(r.images.first,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.meeting_room,
                                color: Colors.white24)))
                    : const Icon(Icons.meeting_room, color: Colors.white24),
                title: Text(r.title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '${FormatUtils.vnd(r.basePrice)} / giờ',
                    style: const TextStyle(
                        color: Color(0xFFFFD700), fontSize: 12)),
                trailing: showActions
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline,
                                color: Colors.green),
                            onPressed: () => _approveRoom(r),
                            tooltip: 'Duyệt',
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined,
                                color: Colors.redAccent),
                            onPressed: () => _rejectRoom(r),
                            tooltip: 'Từ chối',
                          ),
                        ],
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Đang hoạt động',
                            style: TextStyle(
                                color: Colors.green, fontSize: 11)),
                      ),
              ),
            );
          },
        );
      },
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          labelColor: const Color(0xFFFFD700),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Chờ duyệt'),
            Tab(text: 'Đang hoạt động'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRoomList(_streamByStatus('pending_review'), showActions: true),
          _buildRoomList(_streamByStatus('available')),
        ],
      ),
    );
  }
}
