import '../models/room_model.dart';

/// DTO for updating an existing room listing.
/// Used by [EditRoomScreen] → [RoomService.updateRoom].
class UpdateRoomDTO {
  final String roomId;
  final String? title;
  final String? description;
  final List<String>? images;

  /// Base price per hour in VND.
  final double? basePrice;

  /// Valid statuses: available | maintenance | unavailable
  final String? status;

  final List<String>? amenities;
  final int? quantity;

  const UpdateRoomDTO({
    required this.roomId,
    this.title,
    this.description,
    this.images,
    this.basePrice,
    this.status,
    this.amenities,
    this.quantity,
  });

  static const _validStatuses = {'available', 'maintenance', 'unavailable'};

  String? validate() {
    if (roomId.trim().isEmpty) return 'roomId is required';
    if (title != null && title!.trim().isEmpty) {
      return 'Tên phòng không được để trống';
    }
    if (basePrice != null && basePrice! <= 0) {
      return 'Giá phòng phải lớn hơn 0';
    }
    if (status != null && !_validStatuses.contains(status)) {
      return 'Invalid status: $status';
    }
    if (quantity != null && quantity! < 1) {
      return 'Số lượng phòng phải ít nhất là 1';
    }
    return null;
  }

  /// Merge changes onto an existing [RoomModel].
  RoomModel applyTo(RoomModel existing) {
    return existing.copyWith(
      title: title?.trim() ?? existing.title,
      description: description?.trim() ?? existing.description,
      images: images ?? existing.images,
      basePrice: basePrice ?? existing.basePrice,
      status: status ?? existing.status,
      amenities: amenities ?? existing.amenities,
      quantity: quantity ?? existing.quantity,
      updatedAt: DateTime.now(),
    );
  }
}
