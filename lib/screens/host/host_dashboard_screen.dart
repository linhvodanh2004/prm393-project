import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/booking_model.dart';
import '../../services/revenue_service.dart';
import '../../services/withdrawal_service.dart';
import '../../utils/format_utils.dart';
import 'host_withdrawal_screen.dart';

class HostDashboardScreen extends StatefulWidget {
  const HostDashboardScreen({super.key});

  @override
  State<HostDashboardScreen> createState() => _HostDashboardScreenState();
}

class _HostDashboardScreenState extends State<HostDashboardScreen> {
  final String? _hostId = FirebaseAuth.instance.currentUser?.uid;
  final RevenueService _revenueService = RevenueService();

  int _selectedYear = DateTime.now().year;

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
        title: const Text('Thống kê', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: _revenueService.getRevenueBookings(_hostId),
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

          final allBookings = snapshot.data ?? [];

          // Filter by selected year
          final yearBookings = allBookings
              .where((b) => b.createdAt.year == _selectedYear)
              .toList();

          // Aggregate by month (1 to 12)
          final Map<int, double> monthlyRevenue = {
            for (var i = 1; i <= 12; i++) i: 0.0,
          };

          double totalRevenueYear = 0.0;
          for (var b in yearBookings) {
            final double price = b.totalPrice;
            monthlyRevenue[b.createdAt.month] =
                (monthlyRevenue[b.createdAt.month] ?? 0) + price;
            totalRevenueYear += price;
          }

          double maxMonthly = monthlyRevenue.values.fold(
            0.0,
            (m, v) => v > m ? v : m,
          );
          if (maxMonthly == 0) {
            maxMonthly = 1; // prevent divide by zero in chart
          }

          // Add 20% buffer on top of max value for better look
          double maxY = maxMonthly * 1.2;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Year selector + Total)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng quan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DropdownButton<int>(
                      dropdownColor: const Color(0xFF1A1A1A),
                      value: _selectedYear,
                      style: const TextStyle(
                        color: Color(0xFFD4A853),
                        fontWeight: FontWeight.bold,
                      ),
                      underline: const SizedBox(),
                      items:
                          [
                                DateTime.now().year - 1,
                                DateTime.now().year,
                                DateTime.now().year + 1,
                              ]
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                  child: Text('Năm $y'),
                                ),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedYear = val);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D2210), Color(0xFF1A1408)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD4A853).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Doanh thu năm',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        FormatUtils.vnd(totalRevenueYear),
                        style: const TextStyle(
                          color: Color(0xFFD4A853),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${yearBookings.length} lượt đăt phòng (confirmed/paid/completed)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Host Wallet Section
                const Text(
                  'Ví Chủ Nhà (Thanh toán qua PAYOS)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<Map<String, double>>(
                  future: WithdrawalService().getHostRevenueStats(_hostId),
                  builder: (context, statSnap) {
                    if (statSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(color: Color(0xFFD4A853)));
                    }
                    final stats = statSnap.data ?? {};
                    final payosRev = stats['payosRevenue'] ?? 0.0;
                    final withdrawn = stats['totalWithdrawn'] ?? 0.0;
                    final avail = stats['availableBalance'] ?? 0.0;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tổng thu PAYOS', style: TextStyle(color: Colors.white70)),
                              Text(FormatUtils.vnd(payosRev),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Đã rút / Đang chờ', style: TextStyle(color: Colors.white70)),
                              Text(FormatUtils.vnd(withdrawn),
                                  style: const TextStyle(color: Colors.orangeAccent)),
                            ],
                          ),
                          const Divider(color: Colors.white24, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Số dư khả dụng', style: TextStyle(color: Colors.white70)),
                              Text(FormatUtils.vnd(avail),
                                  style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HostWithdrawalScreen(),
                                  ),
                                );
                                setState(() {}); // Refresh stats after return
                              },
                              icon: const Icon(Icons.account_balance_wallet_outlined),
                              label: const Text('Rút doanh thu',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD4A853),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),
                const Text(
                  'Biểu đồ doanh thu từng tháng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Chart
                SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              'Tháng ${group.x.toInt() + 1}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text: FormatUtils.vnd(rod.toY),
                                  style: const TextStyle(
                                    color: Color(0xFFD4A853),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'T${value.toInt() + 1}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: maxY / 4,
                            getTitlesWidget: (value, meta) {
                              if (value == maxY) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  FormatUtils.vndCompactNoSymbol(value),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 5,
                        getDrawingHorizontalLine: (value) =>
                            FlLine(color: Colors.white10, strokeWidth: 1),
                      ),
                      barGroups: List.generate(12, (index) {
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: monthlyRevenue[index + 1]!,
                              color: const Color(0xFFD4A853),
                              width: 12,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
