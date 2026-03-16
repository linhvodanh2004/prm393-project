import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = BookingService();

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

  String _fmtCurrency(double p) =>
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(p);

  String _fmtDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildRevenueTab(), _buildRefundTab()],
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
              Text(_fmtCurrency(total),
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
            '${b.userName}  •  ${_fmtDate(b.checkIn)} → ${_fmtDate(b.checkOut)}',
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_fmtCurrency(b.totalPrice),
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
    return StreamBuilder<List<BookingModel>>(
      stream: _service.getAllBookings(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFFFFD700)));
        }

        final cancelled = snap.data!
            .where((b) => b.status == 'cancelled')
            .toList();
        // Refund-eligible = those that had been paid before cancellation (heuristic: totalPrice > 0)
        final refundEligible =
            cancelled.where((b) => b.totalPrice > 0).toList();

        if (refundEligible.isEmpty) {
          return const Center(
              child: Text('Không có giao dịch hoàn tiền',
                  style: TextStyle(color: Colors.white38)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: refundEligible.length,
          itemBuilder: (_, i) {
            final b = refundEligible[i];
            return Card(
              color: const Color(0xFF1A1A1A),
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                title: Text(b.roomTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: Text('${b.userName}  •  Đã hủy',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
                trailing: Text(_fmtCurrency(b.totalPrice),
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }
}
