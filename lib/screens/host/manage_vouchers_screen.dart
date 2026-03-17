import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/voucher_model.dart';
import '../../services/voucher_service.dart';
import '../../DTOs/create_voucher_dto.dart';
import '../../utils/format_utils.dart';

class ManageVouchersScreen extends StatefulWidget {
  /// Pass 'HOST' to manage host-scoped vouchers, 'ADMIN' for global vouchers.
  final String role;

  const ManageVouchersScreen({super.key, required this.role});

  @override
  State<ManageVouchersScreen> createState() => _ManageVouchersScreenState();
}

class _ManageVouchersScreenState extends State<ManageVouchersScreen> {
  final _service = VoucherService();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Stream<List<VoucherModel>> get _stream => widget.role == 'HOST'
      ? _service.getVouchersByHost(_uid)
      : _service.getGlobalVouchers();

  String _fmtDate(DateTime? d) => d == null ? '—' : FormatUtils.dateVi(d);

  void _openForm({VoucherModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _VoucherFormSheet(
        role: widget.role,
        hostId: _uid,
        existing: existing,
        onSaved: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _toggle(VoucherModel v) async {
    try {
      await _service.toggleActive(v.id, !v.isActive);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _delete(VoucherModel v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Xóa voucher', style: TextStyle(color: Colors.white)),
        content: Text('Xóa mã "${v.code}"?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Xóa', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteVoucher(v.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi xóa: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.role == 'HOST' ? 'Voucher của tôi' : 'Voucher toàn cầu';
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title:
            Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'manage_vouchers_fab',
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<VoucherModel>>(
        stream: _stream,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD700)));
          }
          if (snap.hasError) {
            return Center(
                child: Text('Lỗi: ${snap.error}',
                    style: const TextStyle(color: Colors.red)));
          }

          final vouchers = snap.data ?? [];
          if (vouchers.isEmpty) {
            return const Center(
                child: Text('Chưa có voucher nào',
                    style: TextStyle(color: Colors.white38)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vouchers.length,
            itemBuilder: (_, i) => _buildCard(vouchers[i]),
          );
        },
      ),
    );
  }

  Widget _buildCard(VoucherModel v) {
    final discountLabel = v.type == 'PERCENT'
        ? '${v.value.toStringAsFixed(0)}%'
        : FormatUtils.vnd(v.value);

    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(v.code,
                      style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                ),
                Switch(
                  value: v.isActive,
                  onChanged: (_) => _toggle(v),
                  activeThumbColor: const Color(0xFFFFD700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Giảm $discountLabel',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            if (v.minSubtotal > 0)
              Text(
                  'Đơn tối thiểu: ${FormatUtils.vnd(v.minSubtotal)}',
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 12)),
            Text('Hết hạn: ${_fmtDate(v.endAt)}',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _openForm(existing: v),
                  icon: const Icon(Icons.edit_outlined,
                      size: 16, color: Colors.white54),
                  label: const Text('Sửa',
                      style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => _delete(v),
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: Colors.redAccent),
                  label: const Text('Xóa',
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Form Sheet ────────────────────────────────────────────────────────────────

class _VoucherFormSheet extends StatefulWidget {
  final String role;
  final String hostId;
  final VoucherModel? existing;
  final VoidCallback onSaved;

  const _VoucherFormSheet({
    required this.role,
    required this.hostId,
    this.existing,
    required this.onSaved,
  });

  @override
  State<_VoucherFormSheet> createState() => _VoucherFormSheetState();
}

class _VoucherFormSheetState extends State<_VoucherFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _service = VoucherService();

  late TextEditingController _codeCtrl;
  late TextEditingController _valueCtrl;
  late TextEditingController _maxDiscountCtrl;
  late TextEditingController _minSubtotalCtrl;
  String _type = 'FIXED';
  DateTime? _endAt;
  bool _saving = false;
  bool _generatingCode = false;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _codeCtrl = TextEditingController(text: v?.code ?? '');
    _valueCtrl =
        TextEditingController(text: v?.value.toStringAsFixed(0) ?? '');
    _maxDiscountCtrl = TextEditingController(
        text: v?.maxDiscount?.toStringAsFixed(0) ?? '');
    _minSubtotalCtrl = TextEditingController(
        text: (v == null || v.minSubtotal == 0) ? '' : v.minSubtotal.toStringAsFixed(0));
    _type = v?.type ?? 'FIXED';
    _endAt = v?.endAt;

    if (widget.existing == null) {
      _generateNewCode();
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _valueCtrl.dispose();
    _maxDiscountCtrl.dispose();
    _minSubtotalCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateNewCode() async {
    setState(() => _generatingCode = true);
    try {
      final code = await _service.generateUniqueVoucherCode();
      if (!mounted) return;
      _codeCtrl.text = code;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo mã: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingCode = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();

      if (widget.existing != null) {
        // Update uses existing VoucherModel directly
        final voucher = VoucherModel(
          id: widget.existing!.id,
          code: widget.existing!.code,
          scope: widget.role == 'HOST' ? 'HOST' : 'GLOBAL',
          hostId: widget.role == 'HOST' ? widget.hostId : null,
          type: _type,
          value: double.parse(_valueCtrl.text.trim()),
          maxDiscount: _maxDiscountCtrl.text.trim().isNotEmpty
              ? double.tryParse(_maxDiscountCtrl.text.trim())
              : null,
          minSubtotal: double.tryParse(_minSubtotalCtrl.text.trim()) ?? 0,
          endAt: _endAt,
          isActive: widget.existing!.isActive,
          createdBy: widget.hostId,
          createdAt: widget.existing!.createdAt,
          updatedAt: now,
        );
        await _service.updateVoucher(voucher);
      } else {
        final dto = CreateVoucherDTO(
          scope: widget.role == 'HOST' ? 'HOST' : 'GLOBAL',
          hostId: widget.role == 'HOST' ? widget.hostId : null,
          type: _type,
          value: double.parse(_valueCtrl.text.trim()),
          maxDiscount: _maxDiscountCtrl.text.trim().isNotEmpty
              ? double.tryParse(_maxDiscountCtrl.text.trim())
              : null,
          minSubtotal: double.tryParse(_minSubtotalCtrl.text.trim()) ?? 0,
          endAt: _endAt,
          isActive: true,
          createdBy: widget.hostId,
        );
        await _service.createVoucherWithRandomCode(dto);
      }

      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi lưu: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null ? 'Tạo voucher mới' : 'Chỉnh sửa voucher',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _codeCtrl,
                      'Mã voucher (tự tạo)',
                      readOnly: true,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Đang tạo mã...'
                          : null,
                    ),
                  ),
                  if (widget.existing == null) ...[
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Tạo mã mới',
                      onPressed: _generatingCode ? null : _generateNewCode,
                      icon: _generatingCode
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFFD700),
                              ),
                            )
                          : const Icon(
                              Icons.refresh,
                              color: Color(0xFFFFD700),
                            ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Loại giảm:',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(width: 12),
                  _typeChip('FIXED', 'Cố định (₫)'),
                  const SizedBox(width: 8),
                  _typeChip('PERCENT', 'Phần trăm (%)'),
                ],
              ),
              const SizedBox(height: 12),
              _field(_valueCtrl,
                  _type == 'PERCENT' ? 'Giá trị (%)' : 'Giá trị (₫)',
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? 'Số không hợp lệ' : null),
              const SizedBox(height: 12),
              if (_type == 'PERCENT')
                _field(_maxDiscountCtrl, 'Giảm tối đa (₫, bỏ trống = không giới hạn)',
                    keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _field(_minSubtotalCtrl, 'Đơn tối thiểu (₫, bỏ trống = không)',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              // End date picker
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _endAt ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
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
                  if (d != null) setState(() => _endAt = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.white38, size: 16),
                      const SizedBox(width: 10),
                      Text(
                        _endAt == null
                            ? 'Ngày hết hạn (tùy chọn)'
                            : 'Hết hạn: ${FormatUtils.dateVi(_endAt!)}',
                        style: TextStyle(
                            color: _endAt == null
                                ? Colors.white38
                                : Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Text('Lưu',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint,
      {TextInputType? keyboardType,
      bool readOnly = false,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
      validator: validator,
    );
  }

  Widget _typeChip(String value, String label) {
    final selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFD700)
              : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.black : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ),
    );
  }
}
