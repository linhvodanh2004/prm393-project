import '../models/property_model.dart';

/// DTO for creating or updating a host property profile.
/// Used by [EditPropertyScreen] → [PropertyService.saveProperty].
class SavePropertyDTO {
  /// The host's UID. Also serves as the Firestore document ID (1:1 relationship).
  final String hostId;
  final String title;
  final String description;
  final String address;

  /// Cloudinary URL for the property cover image.
  final String coverImage;

  /// House rules / policies list.
  final List<String> policies;

  /// Pass the existing [PropertyModel.createdAt] when updating so it is
  /// preserved. Leave null when creating a new property (service will use now).
  final DateTime? existingCreatedAt;

  const SavePropertyDTO({
    required this.hostId,
    required this.title,
    required this.description,
    required this.address,
    this.coverImage = '',
    this.policies = const [],
    this.existingCreatedAt,
  });

  String? validate() {
    if (hostId.trim().isEmpty) return 'hostId is required';
    if (title.trim().isEmpty) return 'Tên chỗ nghỉ không được để trống';
    if (address.trim().isEmpty) return 'Địa chỉ không được để trống';
    return null;
  }

  PropertyModel toModel() {
    final now = DateTime.now();
    return PropertyModel(
      hostId: hostId,
      title: title.trim(),
      description: description.trim(),
      address: address.trim(),
      coverImage: coverImage,
      policies: policies,
      createdAt: existingCreatedAt ?? now,
      updatedAt: now,
    );
  }
}
