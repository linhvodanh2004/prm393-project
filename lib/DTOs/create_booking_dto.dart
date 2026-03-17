import '../models/booking_model.dart';

/// DTO for creating a new booking.
/// Used by [RoomDetailsScreen] → [BookingService.createBooking].
class CreateBookingDTO {
  final String roomId;
  final String roomTitle;
  final String userId;
  final String userName;
  final String hostId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestCount;

  /// Subtotal before voucher discount.
  final double subtotal;

  /// Final price after voucher discount applied.
  final double totalPrice;

  final String? note;

  // Voucher snapshot (immutable at booking time)
  final String? voucherId;
  final String? voucherCode;
  final String? voucherScope;
  final String? voucherHostId;
  final double? voucherDiscountAmount;

  const CreateBookingDTO({
    required this.roomId,
    required this.roomTitle,
    required this.userId,
    required this.userName,
    required this.hostId,
    required this.checkIn,
    required this.checkOut,
    required this.guestCount,
    required this.subtotal,
    required this.totalPrice,
    this.note,
    this.voucherId,
    this.voucherCode,
    this.voucherScope,
    this.voucherHostId,
    this.voucherDiscountAmount,
  });

  String? validate() {
    if (roomId.trim().isEmpty) return 'roomId is required';
    if (userId.trim().isEmpty) return 'userId is required';
    if (hostId.trim().isEmpty) return 'hostId is required';
    if (!checkOut.isAfter(checkIn)) return 'checkOut must be after checkIn';
    if (guestCount < 1) return 'guestCount must be at least 1';
    if (totalPrice < 0) return 'totalPrice cannot be negative';
    return null;
  }

  BookingModel toModel() {
    return BookingModel(
      id: '',
      roomId: roomId,
      roomTitle: roomTitle,
      userId: userId,
      userName: userName,
      hostId: hostId,
      checkIn: checkIn,
      checkOut: checkOut,
      guestCount: guestCount,
      totalPrice: totalPrice,
      status: 'pending',
      note: note,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      voucherId: voucherId,
      voucherCode: voucherCode,
      voucherScope: voucherScope,
      voucherHostId: voucherHostId,
      voucherDiscountAmount: voucherDiscountAmount,
    );
  }
}
