import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../services/chat_service.dart';
import '../chat/chat_detail_screen.dart';
import '../../utils/format_utils.dart';

class HostBookingsScreen extends StatefulWidget {
  const HostBookingsScreen({super.key});

  @override
  State<HostBookingsScreen> createState() => _HostBookingsScreenState();
}

class _HostBookingsScreenState extends State<HostBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _bookingService = BookingService();
  final _chatService = ChatService();
  String? _hostId;

  @override
  void initState() {
    super.initState();
    _hostId = FirebaseAuth.instance.currentUser?.uid;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmAction(
      BookingModel b, String newStatus, String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        content: Text(
            'Xác nhận "$label" cho booking của khách ${b.userName}?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(label,
                  style: const TextStyle(color: Color(0xFFD4A853)))),
        ],
      ),
    );
    if (ok != true) return;

    // Double-booking check for confirmations
    if (newStatus == 'confirmed') {
      final hasConflict = await _bookingService.hasDateConflict(
          b.roomId, b.checkIn, b.checkOut,
          excludeBookingId: b.id);
      if (hasConflict && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Không thể xác nhận: Phòng đã có booking trùng ngày'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    try {
      await _bookingService.updateBookingStatus(
        b.id,
        newStatus,
        actorId: _hostId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Đã $label thành công'),
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

  Future<void> _startChatWithGuest(BookingModel b) async {
    try {
      // Fetch guest avatar
      final guestDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(b.userId)
          .get();
      final guestAvatar =
          guestDoc.data()?['photoURL'] as String? ?? '';

      final host = FirebaseAuth.instance.currentUser!;
      final roomId = await _chatService.createOrGetRoom(
        b.userId,
        b.userName,
        guestAvatar,
        host.displayName ?? 'Đối tác',
        host.photoURL ?? '',
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              roomId: roomId,
              targetId: b.userId,
              targetName: b.userName,
              targetAvatar: guestAvatar,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi mở chat: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'confirmed':
        color = Colors.blue;
        label = 'Đã xác nhận';
        break;
      case 'paid':
        color = Colors.green;
        label = 'Đã thanh toán';
        break;
      case 'completed':
        color = Colors.teal;
        label = 'Hoàn thành';
        break;
      case 'rejected':
        color = Colors.redAccent;
        label = 'Từ chối';
        break;
      case 'cancelled':
        color = Colors.grey;
        label = 'Đã hủy';
        break;
      default:
        color = Colors.orange;
        label = 'Chờ duyệt';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBookingCard(BookingModel b,
      {bool showPendingActions = false, bool showCompleteBtn = false}) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 16),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(b.roomTitle,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Text(FormatUtils.vnd(b.totalPrice),
                    style: const TextStyle(
                        color: Color(0xFFD4A853),
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.person, 'Khách: ${b.userName}'),
            const SizedBox(height: 4),
            _infoRow(Icons.calendar_month,
                '${FormatUtils.dateTimeVi(b.checkIn)} → ${FormatUtils.dateTimeVi(b.checkOut)}'),
            const SizedBox(height: 4),
            _infoRow(Icons.group, '${b.guestCount} khách'),
            if (b.note != null && b.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.speaker_notes,
                        size: 13, color: Colors.white38),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(b.note!,
                          style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              fontStyle: FontStyle.italic)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showPendingActions) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _confirmAction(b, 'rejected', 'Từ chối'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side:
                            const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Từ chối'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _confirmAction(b, 'confirmed', 'Xác nhận'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4A853),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Xác nhận'),
                    ),
                  ),
                ] else if (showCompleteBtn) ...[
                  ElevatedButton.icon(
                    onPressed: () =>
                        _confirmAction(b, 'completed', 'Hoàn thành'),
                    icon: const Icon(Icons.check_circle_outline,
                        size: 16),
                    label: const Text('Đánh dấu hoàn thành'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ] else
                  _buildStatusBadge(b.status),
                IconButton(
                  onPressed: () => _startChatWithGuest(b),
                  icon: const Icon(Icons.chat_bubble_outline),
                  color: const Color(0xFFD4A853),
                  tooltip: 'Chat với khách',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.white38),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
            ),
          ],
        ),
      );

  Widget _buildList(List<BookingModel> bookings,
      {bool pendingActions = false, bool completeBtn = false}) {
    if (bookings.isEmpty) {
      return const Center(
          child: Text('Không có dữ liệu',
              style: TextStyle(color: Colors.white38)));
    }
    return RefreshIndicator(
      color: const Color(0xFFD4A853),
      backgroundColor: const Color(0xFF1A1A1A),
      onRefresh: () async => setState(() {}),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (_, i) => _buildBookingCard(bookings[i],
            showPendingActions: pendingActions,
            showCompleteBtn: completeBtn),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hostId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
            child: Text('Vui lòng đăng nhập',
                style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Quản lý Booking',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4A853),
          labelColor: const Color(0xFFD4A853),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Chờ duyệt'),
            Tab(text: 'Đã xác nhận'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: _bookingService.getBookingsByHost(_hostId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFD4A853)));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Lỗi: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent)));
          }

          final all = snapshot.data ?? [];
          // Auto finalize outdated bookings (time-based)
          _bookingService.autoFinalizeByTime(all);
          final pending =
              all.where((b) => b.status == 'pending').toList();
          final confirmed =
              all.where((b) => b.status == 'confirmed').toList();
          final paid = all.where((b) => b.status == 'paid').toList();
          final history = all
              .where((b) =>
                  b.status == 'completed' ||
                  b.status == 'rejected' ||
                  b.status == 'cancelled')
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(pending, pendingActions: true),
              // Confirmed tab: shows paid (mark complete) + confirmed (status only)
              _buildList([...paid, ...confirmed],
                  completeBtn: paid.isNotEmpty),
              _buildList(history),
            ],
          );
        },
      ),
    );
  }
}
