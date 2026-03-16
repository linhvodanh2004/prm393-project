import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/room_model.dart';
import '../../models/booking_model.dart';
import '../../models/daily_price_model.dart';
import '../../services/booking_service.dart';
import '../../services/room_service.dart';

class RoomDetailsScreen extends StatefulWidget {
  final RoomModel room;
  const RoomDetailsScreen({super.key, required this.room});

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  final _firestore = FirebaseFirestore.instance;

  DateTime? _checkIn;
  DateTime? _checkOut;
  int _guestCount = 1;
  List<DailyPriceModel> _dailyPrices = [];
  bool _loadingPrices = false;
  bool _submitting = false;
  int _imageIndex = 0;
  final PageController _pageController = PageController();

  // Voucher state
  final TextEditingController _voucherController = TextEditingController();
  String? _appliedVoucherId;
  String? _appliedVoucherCode;
  String? _appliedVoucherScope;
  String? _appliedVoucherHostId;
  double _voucherDiscountAmount = 0;
  String? _voucherError;
  bool _checkingVoucher = false;

  @override
  void initState() {
    super.initState();
    _loadDailyPrices();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyPrices() async {
    setState(() => _loadingPrices = true);
    try {
      _dailyPrices = await RoomService().getDailyPrices(widget.room.id).first;
    } catch (_) {
      _dailyPrices = [];
    }
    if (mounted) setState(() => _loadingPrices = false);
  }

  bool _isDateBlocked(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    return _dailyPrices.any(
        (dp) => DateFormat('yyyy-MM-dd').format(dp.date) == key && dp.isBlocked);
  }

  double _priceForDate(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final overrides = _dailyPrices
        .where((dp) =>
            DateFormat('yyyy-MM-dd').format(dp.date) == key && !dp.isBlocked);
    if (overrides.isNotEmpty) return overrides.first.price;
    return widget.room.basePrice;
  }

  double get _subtotal {
    if (_checkIn == null || _checkOut == null) return 0;
    double total = 0;
    DateTime cur = _checkIn!;
    while (cur.isBefore(_checkOut!)) {
      total += _priceForDate(cur);
      cur = cur.add(const Duration(days: 1));
    }
    return total;
  }

  double get _totalAfterDiscount =>
      (_subtotal - _voucherDiscountAmount).clamp(0, double.infinity);

  int get _nights {
    if (_checkIn == null || _checkOut == null) return 0;
    return _checkOut!.difference(_checkIn!).inDays;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFD700),
            onPrimary: Colors.black,
            surface: Color(0xFF1A1A1A),
          ),
        ),
        child: child!,
      ),
      selectableDayPredicate: (day, _, __) => !_isDateBlocked(day),
    );
    if (range != null) {
      setState(() {
        _checkIn = range.start;
        _checkOut = range.end;
        _clearVoucher();
      });
    }
  }

  void _clearVoucher() {
    _appliedVoucherId = null;
    _appliedVoucherCode = null;
    _appliedVoucherScope = null;
    _appliedVoucherHostId = null;
    _voucherDiscountAmount = 0;
    _voucherError = null;
    _voucherController.clear();
  }

  Future<void> _applyVoucher() async {
    final code = _voucherController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    if (_subtotal <= 0) {
      setState(() => _voucherError = 'Vui lòng chọn ngày trước');
      return;
    }

    setState(() {
      _checkingVoucher = true;
      _voucherError = null;
    });

    try {
      final snap = await _firestore
          .collection('vouchers')
          .where('code', isEqualTo: code)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        setState(() => _voucherError = 'Mã giảm giá không hợp lệ hoặc đã hết hạn');
        return;
      }

      final doc = snap.docs.first;
      final data = doc.data();

      // Scope check
      final scope = data['scope'] as String? ?? 'GLOBAL';
      if (scope == 'HOST' && data['hostId'] != widget.room.hostId) {
        setState(() => _voucherError = 'Mã này không áp dụng cho phòng này');
        return;
      }

      // Date validity
      final now = DateTime.now();
      final startAt = (data['startAt'] as Timestamp?)?.toDate();
      final endAt = (data['endAt'] as Timestamp?)?.toDate();
      if (startAt != null && now.isBefore(startAt)) {
        setState(() => _voucherError = 'Mã chưa có hiệu lực');
        return;
      }
      if (endAt != null && now.isAfter(endAt)) {
        setState(() => _voucherError = 'Mã đã hết hạn');
        return;
      }

      // Min subtotal check
      final minSubtotal = (data['minSubtotal'] as num?)?.toDouble() ?? 0;
      if (_subtotal < minSubtotal) {
        setState(() => _voucherError =
            'Đơn hàng tối thiểu ${_formatPrice(minSubtotal)} để áp dụng mã này');
        return;
      }

      final discount = _calculateDiscount(data, _subtotal);
      setState(() {
        _appliedVoucherId = doc.id;
        _appliedVoucherCode = code;
        _appliedVoucherScope = scope;
        _appliedVoucherHostId = data['hostId'] as String?;
        _voucherDiscountAmount = discount;
        _voucherError = null;
      });
    } catch (e) {
      setState(() => _voucherError = 'Lỗi kiểm tra mã giảm giá');
    } finally {
      if (mounted) setState(() => _checkingVoucher = false);
    }
  }

  double _calculateDiscount(Map<String, dynamic> v, double subtotal) {
    final type = v['type'] as String? ?? 'FIXED';
    final value = (v['value'] as num?)?.toDouble() ?? 0;
    final maxDiscount = (v['maxDiscount'] as num?)?.toDouble();
    double discount;
    if (type == 'PERCENT') {
      discount = subtotal * value / 100;
      if (maxDiscount != null) discount = discount.clamp(0, maxDiscount);
    } else {
      discount = value;
    }
    return discount.clamp(0, subtotal);
  }

  Future<void> _createBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_checkIn == null || _checkOut == null) {
      _showSnack('Vui lòng chọn ngày check-in và check-out');
      return;
    }
    if (_nights < 1) {
      _showSnack('Check-out phải sau check-in ít nhất 1 ngày');
      return;
    }

    setState(() => _submitting = true);
    try {
      final booking = BookingModel(
        id: '',
        roomId: widget.room.id,
        roomTitle: widget.room.title,
        userId: user.uid,
        userName: user.displayName ?? user.email ?? 'Khách',
        hostId: widget.room.hostId,
        checkIn: _checkIn!,
        checkOut: _checkOut!,
        guestCount: _guestCount,
        totalPrice: _totalAfterDiscount,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        voucherId: _appliedVoucherId,
        voucherCode: _appliedVoucherCode,
        voucherScope: _appliedVoucherScope,
        voucherHostId: _appliedVoucherHostId,
        voucherDiscountAmount:
            _voucherDiscountAmount > 0 ? _voucherDiscountAmount : null,
      );

      await BookingService().createBooking(booking);

      if (mounted) {
        _showSnack('Đặt phòng thành công! Chờ xác nhận từ chủ nhà.',
            color: Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Lỗi đặt phòng: $e', color: Colors.red);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(),
                  const SizedBox(height: 16),
                  _buildAmenities(),
                  const SizedBox(height: 16),
                  _buildDescription(),
                  const SizedBox(height: 24),
                  _buildDateSelector(),
                  const SizedBox(height: 16),
                  _buildGuestSelector(),
                  if (_nights > 0) ...[
                    const SizedBox(height: 16),
                    _buildPriceSummary(),
                    const SizedBox(height: 12),
                    _buildVoucherField(),
                  ],
                  const SizedBox(height: 24),
                  _buildBookButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final images = widget.room.images;
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: const Color(0xFF111111),
      flexibleSpace: FlexibleSpaceBar(
        background: images.isEmpty
            ? Container(
                color: const Color(0xFF1A1A1A),
                child: const Icon(Icons.meeting_room,
                    color: Colors.white24, size: 64),
              )
            : Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _imageIndex = i),
                    itemBuilder: (_, i) => Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF1A1A1A),
                          child: const Icon(Icons.broken_image,
                              color: Colors.white24)),
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _imageIndex ? 16 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _imageIndex
                                  ? const Color(0xFFFFD700)
                                  : Colors.white38,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.room.title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          '${_formatPrice(widget.room.basePrice)} / đêm (giá cơ bản)',
          style: const TextStyle(color: Color(0xFFFFD700), fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildAmenities() {
    if (widget.room.amenities.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.room.amenities
          .map((a) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(a,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ))
          .toList(),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mô tả',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(widget.room.description,
            style: const TextStyle(color: Colors.white70, height: 1.5)),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chọn ngày',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _loadingPrices ? null : _pickDateRange,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: _loadingPrices
                ? const Center(
                    child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFFD700))))
                : Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Color(0xFFFFD700), size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _checkIn == null
                            ? const Text(
                                'Chọn ngày check-in — check-out',
                                style: TextStyle(color: Colors.white54))
                            : Text(
                                '${_fmt(_checkIn!)}  →  ${_fmt(_checkOut!)}  ($_nights đêm)',
                                style: const TextStyle(color: Colors.white)),
                      ),
                      const Icon(Icons.chevron_right,
                          color: Colors.white38, size: 18),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestSelector() {
    return Row(
      children: [
        const Text('Số khách:',
            style: TextStyle(color: Colors.white, fontSize: 15)),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline,
              color: Color(0xFFFFD700)),
          onPressed:
              _guestCount > 1 ? () => setState(() => _guestCount--) : null,
        ),
        Text('$_guestCount',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFFD700)),
          onPressed: () => setState(() => _guestCount++),
        ),
      ],
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _priceRow(
              '$_nights đêm × ${_formatPrice(widget.room.basePrice)}',
              _subtotal),
          if (_voucherDiscountAmount > 0)
            _priceRow('Giảm giá ($_appliedVoucherCode)',
                -_voucherDiscountAmount,
                color: Colors.green),
          const Divider(color: Colors.white12, height: 20),
          _priceRow('Tổng cộng', _totalAfterDiscount,
              style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount,
      {Color? color, TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: style ?? TextStyle(color: color ?? Colors.white70)),
          Text(
            '${amount < 0 ? '-' : ''}${_formatPrice(amount.abs())}',
            style: style ?? TextStyle(color: color ?? Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherField() {
    if (_appliedVoucherId != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Mã "$_appliedVoucherCode" đã được áp dụng',
                  style: const TextStyle(color: Colors.green)),
            ),
            GestureDetector(
              onTap: () => setState(_clearVoucher),
              child: const Icon(Icons.close, color: Colors.green, size: 18),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mã giảm giá',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _voucherController,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Nhập mã...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  errorText: _voucherError,
                  errorStyle:
                      const TextStyle(color: Colors.orangeAccent),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: EdgeInsets.only(
                  top: _voucherError != null ? 0 : 0),
              child: ElevatedButton(
                onPressed: _checkingVoucher ? null : _applyVoucher,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _checkingVoucher
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : const Text('Áp dụng'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBookButton() {
    final canBook = _checkIn != null && _checkOut != null && _nights >= 1;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canBook && !_submitting ? _createBooking : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700),
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.grey[800],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: _submitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black))
            : Text(
                canBook
                    ? 'Đặt phòng — ${_formatPrice(_totalAfterDiscount)}'
                    : 'Chọn ngày để đặt phòng',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
    );
  }

  String _fmt(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M₫';
    }
    return '${(price / 1000).toStringAsFixed(0)}k₫';
  }
}
