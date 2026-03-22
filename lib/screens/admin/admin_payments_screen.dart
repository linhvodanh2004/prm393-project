import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../utils/format_utils.dart';
import '../../models/withdrawal_request_model.dart';
import '../../services/withdrawal_service.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = BookingService();
  final _withdrawalService = WithdrawalService();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Thanh toán & Doanh thu',
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
            Tab(text: 'Doanh thu'),
            Tab(text: 'Hoàn tiền'),
            Tab(text: 'Rút tiền (Host)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildRevenueTab(), _buildRefundTab(), _buildWithdrawalTab()],
      ),
    );
  }

  Widget _buildRevenueTab() {
    return StreamBuilder<List<BookingModel>>(
      stream: _service.getAllBookings(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFFFFD700)));
        }

        final all = snap.data!;
        final paid = all
            .where((b) => b.status == 'paid' || b.status == 'completed')
            .toList();
        final totalRevenue =
            paid.fold<double>(0, (sum, b) => sum + b.totalPrice);

        return Column(
          children: [
            _buildRevenueCard(totalRevenue, paid.length),
            Expanded(
              child: paid.isEmpty
                  ? const Center(
                      child: Text('Chưa có giao dịch',
                          style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: paid.length,
                      itemBuilder: (_, i) =>
                          _buildPaymentTile(paid[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRevenueCard(double total, int count) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1F00), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up,
              color: Color(0xFFFFD700), size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tổng doanh thu',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              Text(FormatUtils.vnd(total),
                  style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              Text('$count giao dịch',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(BookingModel b) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(b.roomTitle,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(
            '${b.userName}  •  ${FormatUtils.dateVi(b.checkIn)} → ${FormatUtils.dateVi(b.checkOut)}',
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(FormatUtils.vnd(b.totalPrice),
                style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: b.status == 'completed'
                    ? Colors.teal.withOpacity(0.2)
                    : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                  b.status == 'completed' ? 'Hoàn thành' : 'Đã TT',
                  style: TextStyle(
                      color: b.status == 'completed'
                          ? Colors.teal
                          : Colors.green,
                      fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundTab() {
    return StreamBuilder<List<WithdrawalRequestModel>>(
      stream: _withdrawalService.getAllRefundRequests(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
        }
        final requests = snap.data!;
        if (requests.isEmpty) {
          return const Center(child: Text('Không có yêu cầu hoàn tiền', style: TextStyle(color: Colors.white38)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          itemBuilder: (_, i) {
            final req = requests[i];
            bool isPending = req.status == 'pending';
            Color statusColor = Colors.orange;
            String statusLabel = 'Chờ xử lý';
            if (req.status == 'approved') { statusColor = Colors.green; statusLabel = 'Đã hoàn tiền'; }
            if (req.status == 'rejected') { statusColor = Colors.red; statusLabel = 'Đã từ chối'; }

            return Card(
              color: const Color(0xFF1A1A1A),
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(FormatUtils.vnd(req.amount),
                            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (req.bookingId != null)
                      Text('Booking: ${req.bookingId!.substring(0, 10)}...', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    Text('Ngân hàng: ${req.bankCode}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('Số TK: ${req.bankAccount}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('Chủ TK: ${req.accountName}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('Ngày yêu cầu: ${FormatUtils.dateTimeVi(req.createdAt)}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    if (req.status == 'rejected' && req.rejectionReason != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Lý do từ chối: ${req.rejectionReason}', style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    if (isPending) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _handleWithdrawalRequest(req, 'rejected'),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                            child: const Text('Từ chối'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _handleWithdrawalRequest(req, 'approved'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            child: const Text('Đã Hoàn CK'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWithdrawalTab() {
    return StreamBuilder<List<WithdrawalRequestModel>>(
      stream: _withdrawalService.getAllRequests(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
        }

        final requests = snap.data!;
        if (requests.isEmpty) {
          return const Center(child: Text('Không có yêu cầu rút tiền', style: TextStyle(color: Colors.white38)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          itemBuilder: (_, i) {
            final req = requests[i];
            bool isPending = req.status == 'pending';
            Color statusColor = Colors.orange;
            String statusLabel = 'Chờ xử lý';
            if (req.status == 'approved') {
              statusColor = Colors.green;
              statusLabel = 'Đã duyệt';
            } else if (req.status == 'rejected') {
              statusColor = Colors.red;
              statusLabel = 'Đã từ chối';
            }

            return Card(
              color: const Color(0xFF1A1A1A),
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(FormatUtils.vnd(req.amount),
                            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 18, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Host ID: ${req.hostId.substring(0, 10)}...', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('Ngân hàng: ${req.bankCode}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('Số tài khoản: ${req.bankAccount}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('Chủ tài khoản: ${req.accountName}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Ngày yêu cầu: ${FormatUtils.dateTimeVi(req.createdAt)}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    if (req.status == 'rejected' && req.rejectionReason != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('Lý do từ chối: ${req.rejectionReason}', style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    if (isPending) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _handleWithdrawalRequest(req, 'rejected'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                            child: const Text('Từ chối'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () => _handleWithdrawalRequest(req, 'approved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Duyệt & Đã CK'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleWithdrawalRequest(WithdrawalRequestModel req, String newStatus) async {
    String? rejectionReason;
    
    if (newStatus == 'rejected') {
      rejectionReason = await showDialog<String>(
        context: context,
        builder: (_) => SimpleDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Lý do từ chối', style: TextStyle(color: Colors.white)),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Sai thông tin ngân hàng'),
              child: const Text('Sai thông tin ngân hàng', style: TextStyle(color: Colors.white70)),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Tên chủ tài khoản không khớp'),
              child: const Text('Tên chủ tài khoản không khớp', style: TextStyle(color: Colors.white70)),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Tài khoản có dấu hiệu bất thường'),
              child: const Text('Tài khoản có dấu hiệu bất thường', style: TextStyle(color: Colors.white70)),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'Khác (Admin sẽ liên hệ)'),
              child: const Text('Khác (Admin sẽ liên hệ)', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      );
      if (rejectionReason == null) return; // user cancelled dialog
    } else {
      final label = 'duyệt';
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text('Xác nhận $label', style: const TextStyle(color: Colors.white)),
          content: Text('Bạn chắc chắn muốn $label yêu cầu rút ${FormatUtils.vnd(req.amount)}?',
              style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(label, style: const TextStyle(color: Colors.green))),
          ],
        ),
      );
      if (ok != true) return;
    }

    try {
      await _withdrawalService.updateRequestStatus(req.id, newStatus, rejectionReason: rejectionReason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật yêu cầu thành công'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }
}
