import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../services/payment_service.dart';
import '../../services/withdrawal_service.dart';
import '../../DTOs/update_booking_status_dto.dart';
import '../../utils/format_utils.dart';
import '../../widgets/profile/user_info_card.dart';
import '../../models/user_model.dart';
import '../../services/medal_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final BookingService _bookingService = BookingService();
  final PaymentService _paymentService = PaymentService();
  final WithdrawalService _withdrawalService = WithdrawalService();
  bool _isLoadingAction = false;

  final _banks = [
    {'code': 'VCB', 'name': 'Vietcombank'},
    {'code': 'TCB', 'name': 'Techcombank'},
    {'code': 'MB', 'name': 'MBBank'},
    {'code': 'ACB', 'name': 'ACB'},
    {'code': 'BIDV', 'name': 'BIDV'},
    {'code': 'VTB', 'name': 'VietinBank'},
    {'code': 'VPB', 'name': 'VPBank'},
  ];

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handlePayment(BookingModel b) async {
    setState(() => _isLoadingAction = true);
    try {
      final checkoutUrl = await _paymentService.createPaymentLink(
        bookingId: b.id,
        amount: b.totalPrice,
      );
      await launchUrl(
        Uri.parse(checkoutUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      _showSnack('Lỗi tạo link thanh toán: $e', color: Colors.orange);
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _updateStatus(BookingModel b, String newStatus) async {
    String? cancelReason;
    final isHostAction = _currentUserId == b.hostId;

    if (newStatus == 'cancelled' || newStatus == 'rejected') {
      List<String> options = isHostAction
          ? [
              'Phòng gặp sự cố kỹ thuật',
              'Khách yêu cầu hủy qua kênh khác',
              'Khách sạn hết phòng do lỗi đồng bộ',
              'Không liên lạc được khách',
              'Khác',
            ]
          : [
              'Thay đổi kế hoạch',
              'Tìm được chỗ tốt hơn',
              'Host yêu cầu tôi hủy',
              'Khác',
            ];

      cancelReason = await showDialog<String>(
        context: context,
        builder: (_) => SimpleDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Lý do hủy/từ chối',
            style: TextStyle(color: Colors.white),
          ),
          children: options
              .map(
                (opt) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, opt),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      opt,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );
      if (cancelReason == null) return; // User cancelled the dialog
    }

    bool isCancelOrRejectPaid =
        (b.status == 'paid') &&
        (newStatus == 'cancelled' || newStatus == 'rejected');

    // Show confirmation dialog with a warning about manual refund if the booking is already paid
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          isCancelOrRejectPaid ? 'Cảnh báo hoàn tiền' : 'Xác nhận hành động',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isCancelOrRejectPaid
              ? 'Đơn đặt phòng này đã được THANH TOÁN qua PAYOS. Nếu tiếp tục hủy/từ chối, bạn sẽ cần phải thỏa thuận HOÀN TIỀN thủ công chuyển khoản 1-1 bên ngoài hệ thống, quá trình này có thể mất 1-3 ngày làm việc.\n\nBạn có chắc chắn muốn thay đổi trạng thái không?'
              : 'Bạn có chắc chắn muốn thay đổi trạng thái sang: $newStatus?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Xác nhận',
              style: TextStyle(
                color: isCancelOrRejectPaid ? Colors.red : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoadingAction = true);
    try {
      await _bookingService.updateBookingStatus(
        b.id,
        UpdateBookingStatusDTO(
          newStatus: newStatus,
          actorId: _currentUserId,
          cancelReason: cancelReason,
        ),
      );
      _showSnack(
        'Cập nhật trạng thái thành $newStatus thành công',
        color: Colors.green,
      );

      // If a PAID PAYOS booking was cancelled, prompt for refund request
      bool wasPaidPayOS =
          (b.status == 'paid' || b.status == 'confirmed') &&
          b.paymentMethod == 'PAYOS';
      bool isCancelAction = newStatus == 'cancelled' || newStatus == 'rejected';
      if (wasPaidPayOS && isCancelAction && mounted) {
        await _showRefundForm(b);
      }
    } catch (e) {
      _showSnack('Lỗi cập nhật: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _showRefundForm(BookingModel b) async {
    final formKey = GlobalKey<FormState>();
    String bankCode = 'VCB';
    String bankAccount = '';
    String accountName = '';
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đăng ký nhận hoàn tiền',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Số tiền: ${FormatUtils.vnd(b.totalPrice)}',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: bankCode,
                      dropdownColor: const Color(0xFF2A2A2A),
                      decoration: const InputDecoration(
                        labelText: 'Ngân hàng',
                        labelStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Color(0xFF2A2A2A),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white),
                      items: _banks
                          .map(
                            (bk) => DropdownMenuItem(
                              value: bk['code'],
                              child: Text('${bk['code']} - ${bk['name']}'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setModalState(() => bankCode = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Số tài khoản',
                        labelStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Color(0xFF2A2A2A),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Vui lòng nhập STK' : null,
                      onSaved: (v) => bankAccount = v!,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Tên chủ tài khoản',
                        labelStyle: TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Color(0xFF2A2A2A),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Vui lòng nhập tên' : null,
                      onSaved: (v) => accountName = v!.toUpperCase(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              'Bỏ qua',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: submitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate())
                                      return;
                                    formKey.currentState!.save();
                                    setModalState(() => submitting = true);
                                    try {
                                      await _withdrawalService
                                          .createRefundRequest(
                                            userId: _currentUserId!,
                                            bookingId: b.id,
                                            amount: b.totalPrice,
                                            bankCode: bankCode,
                                            bankAccount: bankAccount,
                                            accountName: accountName,
                                          );
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (mounted)
                                        _showSnack(
                                          'Gửi yêu cầu hoàn tiền thành công!',
                                          color: Colors.green,
                                        );
                                    } catch (e) {
                                      if (mounted)
                                        _showSnack(
                                          'Lỗi: $e',
                                          color: Colors.red,
                                        );
                                    } finally {
                                      if (ctx.mounted)
                                        setModalState(() => submitting = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD700),
                              foregroundColor: Colors.black,
                            ),
                            child: submitting
                                ? const CircularProgressIndicator(
                                    color: Colors.black,
                                  )
                                : const Text(
                                    'Gửi yêu cầu',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTile(BookingModel b) {
    Color color;
    String text;
    String subText = '';

    if (b.paymentMethod == 'PAYOS') {
      if (b.status == 'pending') {
        color = Colors.orange;
        text = 'Chưa thanh toán (PAYOS)';
        subText = 'Vui lòng thanh toán để giữ phòng.';
      } else if (b.status == 'paid') {
        color = Colors.green;
        text = 'Đã thanh toán (PAYOS)';
        subText = 'Bạn đã thanh toán thành công.';
      } else if (b.status == 'cancelled' || b.status == 'rejected') {
        color = Colors.red;
        text = 'Đã hủy/Từ chối';
        subText = 'Nếu đã thanh toán, vui lòng chờ hoàn tiền.';
      } else if (b.status == 'completed') {
        color = Colors.purple;
        text = 'Hoàn thành';
      } else {
        color = Colors.blue;
        text = b.status.toUpperCase();
      }
    } else {
      // CASH Handling
      switch (b.status) {
        case 'confirmed':
          color = Colors.blue;
          text = 'Đã xác nhận';
          subText = 'Thanh toán tiền mặt tại nơi ở.';
          break;
        case 'paid':
          color = Colors.green;
          text = 'Đã thu tiền mặt';
          break;
        case 'completed':
          color = Colors.purple;
          text = 'Hoàn thành';
          break;
        case 'rejected':
          color = Colors.red;
          text = 'Bị từ chối';
          break;
        case 'cancelled':
          color = Colors.grey;
          text = 'Đã hủy';
          break;
        case 'pending':
        default:
          color = Colors.orange;
          text = 'Chờ duyệt (CASH)';
          subText = 'Đang chờ Host xác nhận.';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subText.isNotEmpty) const SizedBox(height: 4),
                if (subText.isNotEmpty)
                  Text(
                    subText,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGuestProfile(String userId, String fallbackName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              height: 200,
              decoration: const BoxDecoration(
                color: Color(0xFF0D0D0D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFD4A853)),
              ),
            );
          }
          if (!snapshot.data!.exists) {
            return Container(
              height: 200,
              decoration: const BoxDecoration(
                color: Color(0xFF0D0D0D),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: const Center(
                child: Text(
                  'Người dùng không tồn tại.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }
          final userData = UserModel.fromFirestore(snapshot.data!);
          return Container(
            padding: EdgeInsets.only(
              top: 24,
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0D0D0D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                UserInfoCard(userData: userData, fallbackEmail: userData.email),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetails(BookingModel b, bool isHost) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết phòng đăng ký',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _detailRow('Tên phòng:', b.roomTitle),

          if (isHost || _currentUserId != b.userId) ...[
            const SizedBox(height: 8),
            const Text(
              'Khách hàng:',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showGuestProfile(b.userId, b.userName),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF1A1A1A),
                      child: Icon(Icons.person, color: Colors.white54),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.userName.isNotEmpty ? b.userName : 'Khách hàng',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<MedalTier>(
                            future: MedalService().getMedalTier(
                              b.userId,
                              isHost: false,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.hasData &&
                                  snapshot.data != MedalTier.NONE) {
                                return MedalService.buildMedalBadge(
                                  snapshot.data!,
                                  iconSize: 14,
                                  fontSize: 12,
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white38),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ] else
            _detailRow(
              'Khách hàng:',
              b.userName.isNotEmpty ? b.userName : 'Khách hàng',
            ),

          _detailRow('Số khách:', '${b.guestCount} người', icon: Icons.group),
          _detailRow(
            'Thời gian:',
            '${FormatUtils.dateTimeVi(b.checkIn)}\n→ ${FormatUtils.dateTimeVi(b.checkOut)}',
            icon: Icons.calendar_month,
          ),
          _detailRow('Đặt lúc:', FormatUtils.dateTimeVi(b.createdAt)),
          const Divider(color: Colors.white24, height: 32),
          _detailRow(
            'Phương thức thanh toán:',
            b.paymentMethod == 'PAYOS'
                ? 'Trực tuyến (PAYOS)'
                : 'Tiền mặt (CASH)',
            valueColor: b.paymentMethod == 'PAYOS'
                ? Colors.deepPurpleAccent
                : Colors.teal,
          ),
          if (b.voucherCode != null)
            _detailRow(
              'Voucher áp dụng:',
              b.voucherCode!,
              valueColor: Colors.green,
            ),
          _detailRow(
            'Giảm giá:',
            '-${FormatUtils.vnd(b.voucherDiscountAmount)}',
            valueColor: Colors.green,
          ),
          if (b.cancelReason != null &&
              (b.status == 'cancelled' || b.status == 'rejected'))
            _detailRow(
              'Lý do:',
              b.cancelReason!,
              valueColor: Colors.redAccent,
              isBold: true,
            ),
          const SizedBox(height: 8),
          _detailRow(
            'Tổng tiền:',
            FormatUtils.vnd(b.totalPrice),
            valueColor: const Color(0xFFD4A853),
            isBold: true,
            fontSize: 18,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    IconData? icon,
    Color? valueColor,
    bool isBold = false,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white54, size: 16),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(BookingModel b) {
    final bool isUser = _currentUserId == b.userId;
    final bool isHost = _currentUserId == b.hostId;
    List<Widget> buttons = [];

    // --- User Actions ---
    if (isUser) {
      if (b.status == 'pending' && b.paymentMethod == 'PAYOS') {
        buttons.add(
          _actionButton(
            'Thanh toán lại PAYOS',
            Colors.deepPurple,
            () => _handlePayment(b),
          ),
        );
      }
      if (b.status == 'pending' ||
          b.status == 'confirmed' ||
          b.status == 'paid') {
        buttons.add(
          _actionButton(
            'Hủy phòng',
            Colors.red,
            () => _updateStatus(b, 'cancelled'),
          ),
        );
      }
      // Allow re-submitting refund if previously rejected
      if ((b.status == 'cancelled' || b.status == 'rejected') &&
          b.paymentMethod == 'PAYOS' &&
          (b.refundStatus == 'rejected' ||
              (b.refundStatus == null && b.totalPrice > 0))) {
        buttons.add(
          _actionButton(
            'Đăng ký hoàn tiền',
            Colors.orange,
            () => _showRefundForm(b),
          ),
        );
      }
    }

    // --- Host Actions ---
    if (isHost) {
      if (b.status == 'pending') {
        buttons.add(
          _actionButton(
            'Xác nhận chờ thanh toán',
            Colors.blue,
            () => _updateStatus(b, 'confirmed'),
          ),
        );
        buttons.add(
          _actionButton(
            'Từ chối khách',
            Colors.red,
            () => _updateStatus(b, 'rejected'),
          ),
        );
      } else if (b.status == 'confirmed') {
        buttons.add(
          _actionButton(
            'Đã nhận tiền mặt',
            Colors.green,
            () => _updateStatus(b, 'paid'),
          ),
        );
        buttons.add(
          _actionButton(
            'Hủy lịch khách',
            Colors.red,
            () => _updateStatus(b, 'cancelled'),
          ),
        );
      } else if (b.status == 'paid') {
        buttons.add(
          _actionButton(
            'Hoàn thành (Check-out)',
            Colors.purple,
            () => _updateStatus(b, 'completed'),
          ),
        );
        buttons.add(
          _actionButton(
            'Hủy & Hoàn tiền PAYOS',
            Colors.red,
            () => _updateStatus(b, 'cancelled'),
          ),
        );
      }
    }

    return buttons;
  }

  Widget _actionButton(String label, Color color, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoadingAction ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.2),
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color.withValues(alpha: 0.5)),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text(
          'Chi tiết Booking',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists)
            return const Center(
              child: Text(
                'Booking deleted',
                style: TextStyle(color: Colors.white),
              ),
            );

          final booking = BookingModel.fromMap(
            snapshot.data!.data() as Map<String, dynamic>,
            snapshot.data!.id,
          );
          final actions = _buildActionButtons(booking);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusTile(booking),
                const SizedBox(height: 24),
                _buildDetails(booking, _currentUserId == booking.hostId),
                const SizedBox(height: 24),
                if (_isLoadingAction)
                  const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD4A853)),
                  ),
                if (!_isLoadingAction && actions.isNotEmpty) ...actions,
              ],
            ),
          );
        },
      ),
    );
  }
}
