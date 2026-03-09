import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../services/notification_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -- Booking CRUD --

  // Stream a host's bookings
  Stream<List<BookingModel>> getBookingsByHost(String hostId) {
    return _firestore
        .collection('bookings')
        .where('hostId', isEqualTo: hostId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Stream a user's bookings
  Stream<List<BookingModel>> getBookingsByUser(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Create a new booking
  Future<String> createBooking(BookingModel booking) async {
    final docRef = await _firestore.collection('bookings').add(booking.toMap());

    // Notify host
    await NotificationService().createNotification(
      recipientId: booking.hostId,
      title: 'Đơn đặt phòng mới!',
      body: 'Khách ${booking.userName} vừa đặt phòng ${booking.roomTitle}.',
      type: 'booking',
      relatedId: docRef.id,
    );

    return docRef.id;
  }

  // Update a booking's status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Notify user
    final doc = await _firestore.collection('bookings').doc(bookingId).get();
    if (doc.exists) {
      final b = BookingModel.fromMap(doc.data()!, doc.id);
      String statusVi = status == 'confirmed'
          ? 'được xác nhận'
          : status == 'rejected'
          ? 'bị từ chối'
          : status == 'paid'
          ? 'đã thanh toán'
          : status == 'cancelled'
          ? 'đã bị hủy'
          : status;

      await NotificationService().createNotification(
        recipientId: b.userId,
        title: 'Cập nhật trạng thái đặt phòng',
        body: 'Đơn đặt phòng "${b.roomTitle}" của bạn $statusVi.',
        type: 'booking',
        relatedId: bookingId,
      );
    }
  }

  // Add notes/chat messages context to an active booking
  Future<void> updateBookingNote(String bookingId, String note) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
