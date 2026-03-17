import '../models/room_model.dart';

/// DTO for creating a new room listing.
/// Used by [ManageRoomsScreen] / [EditRoomScreen] → [RoomService.createRoom].
class CreateRoomDTO {
  final String hostId;
  final String title;
  final String description;
  final List<String> images;

  /// Base price per hour in VND.
  final double basePrice;

  final List<String> amenities;
  final int quantity;

  const CreateRoomDTO({
    required this.hostId,
    required this.title,
    required this.description,
    required this.images,
    required this.basePrice,
    required this.amenities,
    this.quantity = 1,
  });

  String? validate() {
    if (hostId.trim().isEmpty) return 'hostId is required';
    if (title.trim().isEmpty) return 'Tên phòng không được để trống';
    if (description.trim().isEmpty) return 'Mô tả không được để trống';
    if (basePrice <= 0) return 'Giá phòng phải lớn hơn 0';
    if (quantity < 1) return 'Số lượng phòng phải ít nhất là 1';
    return null;
  }

  RoomModel toModel() {
    final now = DateTime.now();
    return RoomModel(
      id: '',
      hostId: hostId,
      title: title.trim(),
      description: description.trim(),
      images: images,
      basePrice: basePrice,
      status: 'available',
      quantity: quantity,
      amenities: amenities,
      createdAt: now,
      updatedAt: now,
    );
  }
}
