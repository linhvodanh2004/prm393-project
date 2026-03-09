import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../services/chat_service.dart';
import '../chat/chat_detail_screen.dart';
import '../../widgets/common/notification_badge_icon.dart';

class UserBookingsScreen extends StatefulWidget {
  const UserBookingsScreen({super.key});

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookingService _bookingService = BookingService();
  final ChatService _chatService = ChatService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCurrency(double price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _startChatWithHost(BookingModel b) async {
    try {
      final userName =
          FirebaseAuth.instance.currentUser?.displayName ?? 'Khách';
      final userAvatar = FirebaseAuth.instance.currentUser?.photoURL ?? '';

      // Host Name isn't directly in BookingModel right now, so we pass 'Chủ nhà' as fallback
      final roomId = await _chatService.createOrGetRoom(
        b.hostId,
        'Chủ nhà', // Fallback, would be better to fetch actual Host Name
        '',
        userName,
        userAvatar,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              roomId: roomId,
              targetId: b.hostId,
              targetName: 'Chủ nhà',
              targetAvatar: '',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi mở chat: $e')));
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'confirmed':
        color = Colors.blue;
        text = 'Đã xác nhận (Chờ TT)';
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
      case 'cancelled':
        color = Colors.red;
        text = status == 'rejected' ? 'Bị từ chối' : 'Đã hủy';
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
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  Widget _buildBookingList(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có dữ liệu',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final b = bookings[index];
        return Card(
          color: const Color(0xFF1A1A1A),
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Room Name & Status)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        b.roomTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusBadge(b.status),
                  ],
                ),
                const SizedBox(height: 12),

                // Details and Chat Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            Icons.calendar_month,
                            '${_formatDate(b.checkIn)} - ${_formatDate(b.checkOut)}',
                          ),
                          const SizedBox(height: 4),
                          _buildInfoRow(
                            Icons.group,
                            'Số khách: ${b.guestCount}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatCurrency(b.totalPrice),
                            style: const TextStyle(
                              color: Color(0xFFD4A853),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _startChatWithHost(b),
                      icon: const Icon(Icons.chat_bubble_outline),
                      color: const Color(0xFFD4A853),
                      tooltip: 'Nhắn tin cho Chủ nhà',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(
          child: Text(
            'Vui lòng đăng nhập',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text(
          'Booking của tôi',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        actions: const [NotificationBadgeIcon()],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4A853),
          labelColor: const Color(0xFFD4A853),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Sắp tới'),
            Tab(text: 'Đợi duyệt'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: _bookingService.getBookingsByUser(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4A853)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi tải dữ liệu: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final bookings = snapshot.data ?? [];

          final upcoming = bookings
              .where((b) => b.status == 'confirmed' || b.status == 'paid')
              .toList();
          final pending = bookings.where((b) => b.status == 'pending').toList();
          final history = bookings
              .where(
                (b) =>
                    b.status == 'completed' ||
                    b.status == 'rejected' ||
                    b.status == 'cancelled',
              )
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(upcoming),
              _buildBookingList(pending),
              _buildBookingList(history),
            ],
          );
        },
      ),
    );
  }
}
