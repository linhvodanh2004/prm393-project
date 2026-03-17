/// DTO for updating a booking's status.
/// Used by [BookingService.updateBookingStatus].
class UpdateBookingStatusDTO {
  /// Valid statuses: pending | confirmed | rejected | paid | completed | cancelled
  final String newStatus;

  /// UID of the actor performing the update.
  /// Pass [userId] when the user cancels; pass [hostId] for host actions;
  /// pass 'ADMIN' for admin force-actions.
  final String? actorId;

  const UpdateBookingStatusDTO({
    required this.newStatus,
    this.actorId,
  });

  static const _validStatuses = {
    'pending',
    'confirmed',
    'rejected',
    'paid',
    'completed',
    'cancelled',
  };

  String? validate() {
    if (!_validStatuses.contains(newStatus)) {
      return 'Invalid status: $newStatus';
    }
    return null;
  }
}
