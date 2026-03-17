/// DTO for sending a chat message.
/// Used by [ChatDetailScreen] → [ChatService.sendMessage].
class SendMessageDTO {
  final String roomId;
  final String targetId;
  final String text;

  const SendMessageDTO({
    required this.roomId,
    required this.targetId,
    required this.text,
  });

  String? validate() {
    if (roomId.trim().isEmpty) return 'roomId is required';
    if (targetId.trim().isEmpty) return 'targetId is required';
    if (text.trim().isEmpty) return 'Tin nhắn không được để trống';
    return null;
  }
}
