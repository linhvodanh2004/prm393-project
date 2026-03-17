import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/room_model.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../utils/format_utils.dart';
import '../profile/host_public_profile_screen.dart';

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
  final bool _loadingPrices = false;
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
  }

  @override
  void dispose() {
    _pageController.dispose();
    _voucherController.dispose();
    super.dispose();
  }




  double get _subtotal {
    if (_checkIn == null || _checkOut == null) return 0;
    return _hours * widget.room.basePrice;
  }

  double get _totalAfterDiscount =>
      (_subtotal - _voucherDiscountAmount).clamp(0, double.infinity);

  int get _hours {
    if (_checkIn == null || _checkOut == null) return 0;
    final diff = _checkOut!.difference(_checkIn!);
    // Floor rounding: total seconds / 3600
    return (diff.inSeconds / 3600.0).floor();
  }

  Future<void> _pickDateTimeRange() async {
    final now = DateTime.now();

    // 1) Pick Check-in Date
    final checkInDate = await showDatePicker(
      context: context,
      initialDate: _checkIn ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
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
    );

    if (checkInDate == null) return;

    // 2) Pick Check-in Time
    if (!mounted) return;
    final checkInTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_checkIn ?? now),
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
    );

    if (checkInTime == null) return;

    final start = DateTime(
      checkInDate.year,
      checkInDate.month,
      checkInDate.day,
      checkInTime.hour,
      checkInTime.minute,
    );

    // 3) Pick Check-out Date (can be different from check-in date)
    if (!mounted) return;
    final checkOutDate = await showDatePicker(
      context: context,
      initialDate: _checkOut ?? start,
      firstDate: start,
      lastDate: now.add(const Duration(days: 90)),
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
    );

    if (checkOutDate == null) return;

    // 4) Pick Check-out Time
    if (!mounted) return;
    final checkOutTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _checkOut ?? start.add(const Duration(hours: 2)),
      ),
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
    );

    if (checkOutTime == null) return;

    final end = DateTime(
      checkOutDate.year,
      checkOutDate.month,
      checkOutDate.day,
      checkOutTime.hour,
      checkOutTime.minute,
    );

    if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thời gian trả phòng phải sau thời gian nhận phòng')),
        );
      }
      return;
    }

    setState(() {
      _checkIn = start;
      _checkOut = end;
      _clearVoucher();
    });
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
            'Đơn hàng tối thiểu ${FormatUtils.vndCompact(minSubtotal)} để áp dụng mã này');
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
    if (_hours < 1) {
      _showSnack('Check-out phải sau check-in ít nhất 1 giờ');
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
                  if (_hours > 0) ...[
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
      actions: [
        IconButton(
          tooltip: 'Thông tin chủ nhà',
          icon: const Icon(Icons.person_outline, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HostPublicProfileScreen(
                  hostId: widget.room.hostId,
                  initialRoomId: widget.room.id,
                ),
              ),
            );
          },
        ),
      ],
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
                      errorBuilder: (context, error, stackTrace) => Container(
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
          '${FormatUtils.vndCompact(widget.room.basePrice)} / giờ (giá cơ bản)',
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
        const Text('Chọn thời gian',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _loadingPrices ? null : _pickDateTimeRange,
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
                                'Chọn thời gian nhận — trả phòng',
                                style: TextStyle(color: Colors.white54))
                            : Text(
                                '${FormatUtils.dateTimeVi(_checkIn!)}  →  ${FormatUtils.dateTimeVi(_checkOut!)}  ($_hours giờ)',
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
              '$_hours giờ × ${FormatUtils.vndCompact(widget.room.basePrice)}',
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
            '${amount < 0 ? '-' : ''}${FormatUtils.vndCompact(amount.abs())}',
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
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
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
    final canBook = _checkIn != null && _checkOut != null && _hours >= 1;
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
                    ? 'Đặt phòng — ${FormatUtils.vndCompact(_totalAfterDiscount)}'
                    : 'Chọn thời gian để đặt phòng',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
    );
  }
}
