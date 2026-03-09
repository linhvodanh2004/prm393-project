import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../services/chat_service.dart';
import '../chat/chat_detail_screen.dart';
import '../../widgets/common/notification_badge_icon.dart';

class HostBookingsScreen extends StatefulWidget {
  const HostBookingsScreen({super.key});

  @override
  State<HostBookingsScreen> createState() => _HostBookingsScreenState();
}

class _HostBookingsScreenState extends State<HostBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookingService _bookingService = BookingService();
  final ChatService _chatService = ChatService();
  final String? _hostId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    // 3 Tabs: Chờ xác nhận (pending), Đã xác nhận (confirmed), Lịch sử (paid/completed/rejected)
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

  Future<void> _updateBookingStatus(String id, String status) async {
    try {
      await _bookingService.updateBookingStatus(id, status);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã cập nhật trạng thái')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi cập nhật: $e')));
      }
    }
  }

  Future<void> _startChatWithUser(BookingModel b) async {
    try {
      // In a real app we'd fetch the host's actual profile details to pass here
      // For now, defaulting with a placeholder if unavailable in booking context
      final hostName = FirebaseAuth.instance.currentUser?.displayName ?? 'Host';
      final hostAvatar = FirebaseAuth.instance.currentUser?.photoURL ?? '';

      final roomId = await _chatService.createOrGetRoom(
        b.userId,
        b.userName,
        '', // Assuming booking model doesn't hold user avatar currently
        hostName,
        hostAvatar,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              roomId: roomId,
              targetId: b.userId,
              targetName: b.userName,
              targetAvatar: '', // Pass user avatar if you update booking model
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

  @override
  Widget build(BuildContext context) {
    if (_hostId == null) {
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
          'Quản lý Booking',
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
            Tab(text: 'Chờ duyệt'),
            Tab(text: 'Đã xác nhận'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: _bookingService.getBookingsByHost(_hostId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4A853)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final allBookings = snapshot.data ?? [];

          final pendingBookings = allBookings
              .where((b) => b.status == 'pending')
              .toList();
          final confirmedBookings = allBookings
              .where((b) => b.status == 'confirmed')
              .toList();
          final historyBookings = allBookings
              .where(
                (b) =>
                    b.status == 'paid' ||
                    b.status == 'completed' ||
                    b.status == 'rejected' ||
                    b.status == 'cancelled',
              )
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(pendingBookings, showActions: true),
              _buildBookingList(confirmedBookings, showStatusOnly: true),
              _buildBookingList(historyBookings, showStatusOnly: true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingList(
    List<BookingModel> bookings, {
    bool showActions = false,
    bool showStatusOnly = false,
  }) {
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
                // Header: Room Name & Price
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
                const SizedBox(height: 12),

                // Booking Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(Icons.person, 'Khách: ${b.userName}'),
                          const SizedBox(height: 4),
                          _buildInfoRow(
                            Icons.calendar_month,
                            '${_formatDate(b.checkIn)} - ${_formatDate(b.checkOut)}',
                          ),
                          const SizedBox(height: 4),
                          _buildInfoRow(
                            Icons.group,
                            'Số khách: ${b.guestCount}',
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _startChatWithUser(b),
                      icon: const Icon(Icons.chat_bubble_outline),
                      color: const Color(0xFFD4A853),
                      tooltip: 'Nhắn tin cho khách',
                    ),
                  ],
                ),

                // Optional Note
                if (b.note != null && b.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.speaker_notes,
                          size: 14,
                          color: Colors.white54,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ghi chú: ${b.note}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),

                // Actions or Status Badge
                if (showActions)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _updateBookingStatus(b.id, 'rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Từ chối'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _updateBookingStatus(b.id, 'confirmed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4A853),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Chấp nhận'),
                        ),
                      ),
                    ],
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildStatusBadge(b.status),
                  ),
              ],
            ),
          ),
        );
      },
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
      case 'cancelled':
        color = Colors.redAccent;
        label = 'Đã huỷ';
        break;
      default:
        color = Colors.grey;
        label = 'Chờ xử lý';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
