import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../DTOs/update_booking_status_dto.dart';
import '../../utils/format_utils.dart';
import 'admin_revenue_screen.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final _service = BookingService();
  String? _filterStatus;

  final _statuses = const [
    null,
    'pending',
    'confirmed',
    'paid',
    'completed',
    'cancelled',
    'rejected',
  ];

  final _statusLabels = const {
    null: 'Tất cả',
    'pending': 'Chờ duyệt',
    'confirmed': 'Đã xác nhận',
    'paid': 'Đã thanh toán',
    'completed': 'Hoàn thành',
    'cancelled': 'Đã hủy',
    'rejected': 'Bị từ chối',
  };

  Future<void> _forceAction(
      BuildContext context, BookingModel b, String action) async {
    final label = action == 'cancel' ? 'Hủy' : 'Hoàn thành';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('$label booking',
            style: const TextStyle(color: Colors.white)),
        content: Text('Bạn chắc chắn muốn $label booking "${b.roomTitle}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(label,
                  style: const TextStyle(color: Color(0xFFFFD700)))),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final newStatus = action == 'cancel' ? 'cancelled' : 'completed';
      await _service.updateBookingStatus(
        b.id,
        UpdateBookingStatusDTO(newStatus: newStatus, actorId: 'ADMIN'),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Đã $label booking'),
            behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'rejected':
      case 'cancelled':
        return Colors.redAccent;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Tất cả Booking',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Doanh thu nền tảng',
            icon: const Icon(Icons.show_chart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminRevenueScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: _statuses
            .map((s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_statusLabels[s] ?? 'Tất cả',
                        style: TextStyle(
                            color: _filterStatus == s
                                ? Colors.black
                                : Colors.white70,
                            fontSize: 12)),
                    selected: _filterStatus == s,
                    selectedColor: const Color(0xFFFFD700),
                    backgroundColor: const Color(0xFF1A1A1A),
                    checkmarkColor: Colors.black,
                    onSelected: (_) =>
                        setState(() => _filterStatus = s),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<List<BookingModel>>(
      stream: _service.getAllBookings(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFFFFD700)));
        }
        if (snap.hasError) {
          return Center(
              child: Text('Lỗi: ${snap.error}',
                  style: const TextStyle(color: Colors.red)));
        }

        var bookings = snap.data!;
        if (_filterStatus != null) {
          bookings = bookings
              .where((b) => b.status == _filterStatus)
              .toList();
        }

        if (bookings.isEmpty) {
          return const Center(
              child: Text('Không có booking',
                  style: TextStyle(color: Colors.white38)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: bookings.length,
          itemBuilder: (_, i) => _buildCard(context, bookings[i]),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, BookingModel b) {
    final color = _statusColor(b.status);
    final canCancel =
        ['pending', 'confirmed'].contains(b.status);
    final canComplete = b.status == 'paid';

    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Text(_statusLabels[b.status] ?? b.status,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Khách: ${b.userName} | Host ID: ${b.hostId.substring(0, 8)}…',
                style:
                    const TextStyle(color: Colors.white38, fontSize: 12)),
            Text(
                '${FormatUtils.dateVi(b.checkIn)} → ${FormatUtils.dateVi(b.checkOut)}',
                style:
                    const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 6),
            Text(FormatUtils.vnd(b.totalPrice),
                style: const TextStyle(
                    color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
            if (canCancel || canComplete) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canComplete)
                    TextButton.icon(
                      onPressed: () =>
                          _forceAction(context, b, 'complete'),
                      icon: const Icon(Icons.check_circle_outline,
                          size: 14, color: Colors.teal),
                      label: const Text('Hoàn thành',
                          style: TextStyle(color: Colors.teal, fontSize: 12)),
                    ),
                  if (canCancel)
                    TextButton.icon(
                      onPressed: () =>
                          _forceAction(context, b, 'cancel'),
                      icon: const Icon(Icons.cancel_outlined,
                          size: 14, color: Colors.redAccent),
                      label: const Text('Hủy bắt buộc',
                          style: TextStyle(
                              color: Colors.redAccent, fontSize: 12)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
