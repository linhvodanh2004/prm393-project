import '../models/daily_price_model.dart';

/// DTO for setting a daily price override on a room.
/// Used by [HostCalendarScreen] → [RoomService.setDailyPrice].
class SetDailyPriceDTO {
  final String roomId;
  final DateTime date;

  /// Overridden hourly price for this specific date (in VND).
  /// Must be > 0 when [isBlocked] is false.
  final double price;

  /// When true, the room is blocked for the entire day; no bookings allowed.
  final bool isBlocked;

  const SetDailyPriceDTO({
    required this.roomId,
    required this.date,
    required this.price,
    this.isBlocked = false,
  });

  String? validate() {
    if (roomId.trim().isEmpty) return 'roomId is required';
    if (!isBlocked && price <= 0) return 'Giá phải lớn hơn 0';
    return null;
  }

  DailyPriceModel toModel() {
    return DailyPriceModel(
      id: '',
      roomId: roomId,
      date: date,
      price: price,
      isBlocked: isBlocked,
    );
  }
}
