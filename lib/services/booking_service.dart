import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../services/notification_service.dart';

// Valid status transitions
const _validTransitions = <String, List<String>>{
  'pending': ['confirmed', 'rejected', 'cancelled'],
  'confirmed': ['paid', 'cancelled', 'completed'],
  'paid': ['completed'],
  // Terminal states — no further transitions allowed
  'completed': [],
  'rejected': [],
  'cancelled': [],
};

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<BookingModel>> getBookingsByHost(String hostId) {
    return _firestore
        .collection('bookings')
        .where('hostId', isEqualTo: hostId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BookingModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<BookingModel>> getBookingsByUser(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BookingModel.fromMap(d.data(), d.id)).toList());
  }

  // Admin: all bookings, no filter
  Stream<List<BookingModel>> getAllBookings() {
    return _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => BookingModel.fromMap(d.data(), d.id)).toList());
  }

  Future<String> createBooking(BookingModel booking) async {
    final docRef =
        await _firestore.collection('bookings').add(booking.toMap());
    await NotificationService().createNotification(
      recipientId: booking.hostId,
      title: 'Đơn đặt phòng mới!',
      body:
          'Khách ${booking.userName} vừa đặt phòng ${booking.roomTitle}.',
      type: 'booking',
      relatedId: docRef.id,
    );
    return docRef.id;
  }

  Future<void> updateBookingStatus(
    String bookingId,
    String newStatus, {
    String? actorId,
  }) async {
    final doc =
        await _firestore.collection('bookings').doc(bookingId).get();
    if (!doc.exists) throw Exception('Booking không tồn tại');

    final booking = BookingModel.fromMap(doc.data()!, doc.id);
    final allowed = _validTransitions[booking.status] ?? [];
    if (!allowed.contains(newStatus)) {
      throw Exception(
          'Không thể chuyển trạng thái từ "${booking.status}" sang "$newStatus"');
    }

    await _firestore.collection('bookings').doc(bookingId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final statusLabel = _statusLabel(newStatus);
    // Notify user (host-side actions)
    if (actorId == null || actorId == booking.hostId) {
      await NotificationService().createNotification(
        recipientId: booking.userId,
        title: 'Cập nhật trạng thái đặt phòng',
        body: 'Đơn đặt phòng "${booking.roomTitle}" của bạn $statusLabel.',
        type: 'booking',
        relatedId: bookingId,
      );
    }

    // Notify host (user-side cancel)
    if (newStatus == 'cancelled' && (actorId == booking.userId)) {
      await NotificationService().createNotification(
        recipientId: booking.hostId,
        title: 'Khách đã hủy đặt phòng',
        body: 'Khách ${booking.userName} đã hủy booking "${booking.roomTitle}".',
        type: 'booking',
        relatedId: bookingId,
      );
    }
  }

  /// Auto finalize bookings when current time passes check-out:
  /// - pending  -> cancelled
  /// - confirmed/paid -> completed
  Future<void> autoFinalizeByTime(List<BookingModel> bookings) async {
    final now = DateTime.now();
    for (final b in bookings) {
      if (!b.checkOut.isBefore(now)) continue;

      if (b.status == 'pending') {
        // pending -> cancelled
        await _firestore.collection('bookings').doc(b.id).update({
          'status': 'cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (b.status == 'confirmed' || b.status == 'paid') {
        // confirmed/paid -> completed
        await _firestore.collection('bookings').doc(b.id).update({
          'status': 'completed',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // Check for conflicting confirmed/paid bookings on same room + overlapping dates.
  // Returns true if a conflict exists (should block confirmation).
  Future<bool> hasDateConflict(
      String roomId, DateTime checkIn, DateTime checkOut,
      {String? excludeBookingId}) async {
    final snap = await _firestore
        .collection('bookings')
        .where('roomId', isEqualTo: roomId)
        .where('status', whereIn: ['confirmed', 'paid'])
        .get();

    for (final doc in snap.docs) {
      if (excludeBookingId != null && doc.id == excludeBookingId) continue;
      final b = BookingModel.fromMap(doc.data(), doc.id);
      // Overlap: not (b.checkOut <= checkIn || b.checkIn >= checkOut)
      final overlaps =
          b.checkOut.isAfter(checkIn) && b.checkIn.isBefore(checkOut);
      if (overlaps) return true;
    }
    return false;
  }

  Future<void> updateBookingNote(String bookingId, String note) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'đã được xác nhận';
      case 'rejected':
        return 'bị từ chối';
      case 'paid':
        return 'đã thanh toán';
      case 'cancelled':
        return 'đã bị hủy';
      case 'completed':
        return 'đã hoàn thành';
      default:
        return status;
    }
  }
}
