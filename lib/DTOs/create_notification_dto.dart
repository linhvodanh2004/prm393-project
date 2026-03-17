/// DTO for creating an in-app notification.
/// Used by [NotificationService.createNotification].
class CreateNotificationDTO {
  final String recipientId;
  final String title;
  final String body;

  /// Notification type: 'booking' | 'chat' | 'host_request' | 'system'
  final String type;

  /// ID of related entity (bookingId, chatRoomId, requestId, etc.)
  final String? relatedId;

  const CreateNotificationDTO({
    required this.recipientId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
  });

  static const _validTypes = {'booking', 'chat', 'host_request', 'system'};

  String? validate() {
    if (recipientId.trim().isEmpty) return 'recipientId is required';
    if (title.trim().isEmpty) return 'title is required';
    if (body.trim().isEmpty) return 'body is required';
    if (!_validTypes.contains(type)) return 'Invalid type: $type';
    return null;
  }
}
