import 'package:flutter/material.dart';

import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../utils/format_utils.dart';

class AdminRevenueScreen extends StatefulWidget {
  /// When [embedded] is true the screen is displayed inside a TabBarView
  /// (no AppBar / Scaffold wrapper needed from this widget).
  final bool embedded;

  const AdminRevenueScreen({super.key, this.embedded = false});

  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen> {
  final _service = BookingService();

  DateTime? _from;
  DateTime? _to;
  String? _status; // null=all

  final _statuses = const [
    null,
    'confirmed',
    'paid',
    'completed',
  ];

  final _statusLabels = const {
    null: 'Tất cả',
    'confirmed': 'Đã xác nhận',
    'paid': 'Đã thanh toán',
    'completed': 'Hoàn thành',
  };

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);

  Future<void> _pickFrom() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFD700),
            onPrimary: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (d == null) return;
    setState(() => _from = _startOfDay(d));
  }

  Future<void> _pickTo() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _to ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFD700),
            onPrimary: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (d == null) return;
    setState(() => _to = _endOfDay(d));
  }

  void _clearDates() => setState(() {
        _from = null;
        _to = null;
      });

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        _buildFilters(),
        Expanded(child: _buildBody()),
      ],
    );

    // When embedded inside a TabBarView, skip the outer Scaffold + AppBar.
    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Doanh thu nền tảng',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: body,
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      color: const Color(0xFF111111),
      child: Column(
        children: [
          // Status chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _statuses
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          _statusLabels[s] ?? 'Tất cả',
                          style: TextStyle(
                            color: _status == s ? Colors.black : Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        selected: _status == s,
                        selectedColor: const Color(0xFFFFD700),
                        backgroundColor: const Color(0xFF1A1A1A),
                        checkmarkColor: Colors.black,
                        onSelected: (_) => setState(() => _status = s),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),
          // Date range
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFrom,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(_from == null
                      ? 'Từ ngày'
                      : 'Từ: ${FormatUtils.dateVi(_from!)}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTo,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(_to == null
                      ? 'Đến ngày'
                      : 'Đến: ${FormatUtils.dateVi(_to!)}'),
                ),
              ),
              IconButton(
                tooltip: 'Xóa lọc ngày',
                onPressed: (_from == null && _to == null) ? null : _clearDates,
                icon: const Icon(Icons.clear, color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<List<BookingModel>>(
      stream: _service.getAllBookings(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)));
        }
        if (snap.hasError) {
          return Center(
              child: Text('Lỗi: ${snap.error}',
                  style: const TextStyle(color: Colors.redAccent)));
        }

        var bookings = snap.data!
            .where((b) =>
                b.status == 'confirmed' ||
                b.status == 'paid' ||
                b.status == 'completed')
            .toList();

        if (_status != null) {
          bookings = bookings.where((b) => b.status == _status).toList();
        }
        if (_from != null) {
          bookings = bookings.where((b) => !b.createdAt.isBefore(_from!)).toList();
        }
        if (_to != null) {
          bookings = bookings.where((b) => !b.createdAt.isAfter(_to!)).toList();
        }

        final total = bookings.fold<double>(0, (sum, b) => sum + b.totalPrice);

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.show_chart,
                      color: Color(0xFFFFD700), size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tổng doanh thu (lọc hiện tại)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          FormatUtils.vnd(total),
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${bookings.length} booking',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: bookings.isEmpty
                  ? const Center(
                      child: Text('Không có dữ liệu',
                          style: TextStyle(color: Colors.white38)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: bookings.length,
                      itemBuilder: (_, i) {
                        final b = bookings[i];
                        return Card(
                          color: const Color(0xFF1A1A1A),
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(
                              b.roomTitle,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${b.userName} • ${FormatUtils.dateTimeShortVi(b.createdAt)} • ${b.status}',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 12),
                            ),
                            trailing: Text(
                              FormatUtils.vnd(b.totalPrice),
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

