import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/voucher_model.dart';
import '../../services/voucher_service.dart';
import '../../utils/format_utils.dart';

class UserVouchersScreen extends StatefulWidget {
  const UserVouchersScreen({super.key});

  @override
  State<UserVouchersScreen> createState() => _UserVouchersScreenState();
}

class _UserVouchersScreenState extends State<UserVouchersScreen>
    with SingleTickerProviderStateMixin {
  final _voucherService = VoucherService();
  final _db = FirebaseFirestore.instance;

  late final TabController _tab;
  final Map<String, String> _hostNameCache = {};

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<String> _getHostName(String hostId) async {
    final cached = _hostNameCache[hostId];
    if (cached != null) return cached;
    final doc = await _db.collection('users').doc(hostId).get();
    final data = doc.data();
    final name = (data?['fullName'] ??
            data?['displayName'] ??
            data?['email'] ??
            'Host')
        .toString();
    _hostNameCache[hostId] = name;
    return name;
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép mã voucher'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _discountLabel(VoucherModel v) {
    if (v.type == 'PERCENT') {
      final pct = v.value.toStringAsFixed(0);
      if (v.maxDiscount != null && v.maxDiscount! > 0) {
        return 'Giảm $pct% (tối đa ${FormatUtils.vnd(v.maxDiscount!)})';
      }
      return 'Giảm $pct%';
    }
    return 'Giảm ${FormatUtils.vnd(v.value)}';
  }

  Widget _chip(String text, {Color? color, Color? bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg ?? const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _voucherCard(VoucherModel v) {
    final isHost = v.scope == 'HOST';
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    v.code,
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Sao chép',
                  onPressed: () => _copy(v.code),
                  icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _chip(
                  v.scope == 'GLOBAL' ? 'Toàn sàn' : 'Đối tác',
                  color: v.scope == 'GLOBAL'
                      ? const Color(0xFFD4A853)
                      : Colors.lightBlueAccent,
                  bg: v.scope == 'GLOBAL'
                      ? const Color(0xFFD4A853).withValues(alpha: 0.10)
                      : Colors.lightBlueAccent.withValues(alpha: 0.10),
                ),
                const SizedBox(width: 8),
                if (v.endAt != null)
                  _chip(
                    'HSD: ${FormatUtils.dateVi(v.endAt!)}',
                    color: Colors.white60,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _discountLabel(v),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (v.minSubtotal > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Đơn tối thiểu: ${FormatUtils.vnd(v.minSubtotal)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
            if (isHost && (v.hostId ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              FutureBuilder<String>(
                future: _getHostName(v.hostId!),
                builder: (context, snap) {
                  final name = snap.data ?? '...';
                  return Row(
                    children: [
                      const Icon(Icons.storefront_outlined,
                          size: 14, color: Colors.white38),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalTab() {
    return StreamBuilder<List<VoucherModel>>(
      stream: _voucherService.getActiveGlobalVouchers(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFD4A853)),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Lỗi: ${snap.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }
        final vouchers = (snap.data ?? []).where((v) => v.isValid).toList();
        if (vouchers.isEmpty) {
          return const Center(
            child: Text(
              'Chưa có voucher Toàn sàn',
              style: TextStyle(color: Colors.white38),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vouchers.length,
          itemBuilder: (_, i) => _voucherCard(vouchers[i]),
        );
      },
    );
  }

  Widget _buildHostTab() {
    return StreamBuilder<List<VoucherModel>>(
      stream: _voucherService.getActiveVouchers(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFD4A853)),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Lỗi: ${snap.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }
        final vouchers = (snap.data ?? [])
            .where((v) => v.scope == 'HOST')
            .where((v) => v.isValid)
            .toList();
        if (vouchers.isEmpty) {
          return const Center(
            child: Text(
              'Chưa có voucher Đối tác',
              style: TextStyle(color: Colors.white38),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vouchers.length,
          itemBuilder: (_, i) => _voucherCard(vouchers[i]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Voucher', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: const Color(0xFFD4A853),
          labelColor: const Color(0xFFD4A853),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Toàn sàn'),
            Tab(text: 'Đối tác'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildGlobalTab(),
          _buildHostTab(),
        ],
      ),
    );
  }
}

