import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';

class RevenueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream paid and completed bookings for a specific host
  Stream<List<BookingModel>> getPaidBookings(String hostId) {
    return _firestore
        .collection('bookings')
        .where('hostId', isEqualTo: hostId)
        .where('status', whereIn: ['paid', 'completed'])
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
