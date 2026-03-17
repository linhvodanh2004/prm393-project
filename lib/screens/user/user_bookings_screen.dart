import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../services/chat_service.dart';
import '../chat/chat_detail_screen.dart';
import '../../utils/format_utils.dart';

class UserBookingsScreen extends StatefulWidget {
  const UserBookingsScreen({super.key});

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _bookingService = BookingService();
  final _chatService = ChatService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _startChatWithHost(BookingModel b) async {
    try {
      // Fetch host profile for accurate name + avatar
      final hostDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(b.hostId)
          .get();
      final hostData = hostDoc.data();
      final hostName = hostData?['fullName'] ??
          hostData?['displayName'] ??
          'Chủ nhà';
      final hostAvatar = hostData?['photoURL'] as String? ?? '';

      final user = FirebaseAuth.instance.currentUser!;
      final roomId = await _chatService.createOrGetRoom(
        b.hostId,
        hostName,
        hostAvatar,
        user.displayName ?? 'Khách',
        user.photoURL ?? '',
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              roomId: roomId,
              targetId: b.hostId,
              targetName: hostName,
              targetAvatar: hostAvatar,
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

  Future<void> _cancelBooking(BookingModel b) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Hủy đặt phòng',
            style: TextStyle(color: Colors.white)),
        content: Text(
            'Bạn có chắc muốn hủy đặt phòng "${b.roomTitle}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hủy phòng',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _bookingService.updateBookingStatus(b.id, 'cancelled');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đã hủy đặt phòng'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi hủy phòng: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'confirmed':
        color = Colors.blue;
        text = 'Đã xác nhận';
        break;
      case 'paid':
        color = Colors.green;
        text = 'Đã thanh toán';
        break;
      case 'completed':
        color = Colors.purple;
        text = 'Hoàn thành';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Bị từ chối';
        break;
      case 'cancelled':
        color = Colors.grey;
        text = 'Đã hủy';
        break;
      case 'pending':
      default:
        color = Colors.orange;
        text = 'Chờ duyệt';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBookingCard(BookingModel b, {bool showCancel = false}) {
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
                _buildStatusBadge(b.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_month,
                    size: 14, color: Colors.white54),
                const SizedBox(width: 6),
                Text(
                    '${FormatUtils.dateTimeVi(b.checkIn)} → ${FormatUtils.dateTimeVi(b.checkOut)}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.group, size: 14, color: Colors.white54),
                const SizedBox(width: 6),
                Text('${b.guestCount} khách',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(FormatUtils.vnd(b.totalPrice),
                    style: const TextStyle(
                        color: Color(0xFFD4A853),
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    if (showCancel)
                      TextButton(
                        onPressed: () => _cancelBooking(b),
                        child: const Text('Hủy',
                            style: TextStyle(color: Colors.red)),
                      ),
                    IconButton(
                      onPressed: () => _startChatWithHost(b),
                      icon: const Icon(Icons.chat_bubble_outline),
                      color: const Color(0xFFD4A853),
                      tooltip: 'Nhắn tin chủ nhà',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<BookingModel> bookings, {bool showCancel = false}) {
    if (bookings.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu',
            style: TextStyle(color: Colors.white38, fontSize: 16)),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFFD4A853),
      backgroundColor: const Color(0xFF1A1A1A),
      onRefresh: () async => setState(() {}),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (_, i) =>
            _buildBookingCard(bookings[i], showCancel: showCancel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
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
        title: const Text('Booking của tôi',
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
            Tab(text: 'Sắp tới'),
            Tab(text: 'Chờ duyệt'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: _bookingService.getBookingsByUser(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFD4A853)));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Lỗi: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }

          final all = snapshot.data ?? [];
          final upcoming = all
              .where((b) =>
                  b.status == 'confirmed' || b.status == 'paid')
              .toList();
          final pending =
              all.where((b) => b.status == 'pending').toList();
          final history = all
              .where((b) =>
                  b.status == 'completed' ||
                  b.status == 'rejected' ||
                  b.status == 'cancelled')
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(upcoming),
              _buildList(pending, showCancel: true),
              _buildList(history),
            ],
          );
        },
      ),
    );
  }
}
