import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/withdrawal_request_model.dart';
import 'notification_service.dart';

class WithdrawalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<WithdrawalRequestModel>> getRequestsByHost(String hostId) {
    return _firestore
        .collection('withdrawal_requests')
        .where('hostId', isEqualTo: hostId)
        .where('type', isEqualTo: 'withdrawal')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WithdrawalRequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<WithdrawalRequestModel>> getAllRequests() {
    return _firestore
        .collection('withdrawal_requests')
        .where('type', isEqualTo: 'withdrawal')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WithdrawalRequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<WithdrawalRequestModel>> getAllRefundRequests() {
    return _firestore
        .collection('withdrawal_requests')
        .where('type', isEqualTo: 'refund')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WithdrawalRequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Stream<List<WithdrawalRequestModel>> getRefundsByUser(String userId) {
    return _firestore
        .collection('withdrawal_requests')
        .where('hostId', isEqualTo: userId) // hostId stores requesterId for refunds
        .where('type', isEqualTo: 'refund')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WithdrawalRequestModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> createRequest({
    required String hostId,
    required double amount,
    required String bankCode,
    required String bankAccount,
    required String accountName,
  }) async {
    // Check available balance before creating
    final balance = await getAvailableBalance(hostId);
    if (amount <= 0) throw Exception('Số tiền không hợp lệ');
    if (amount > balance) throw Exception('Số dư không đủ để rút');

    final docRef = await _firestore.collection('withdrawal_requests').add({
      'hostId': hostId,
      'amount': amount,
      'bankCode': bankCode,
      'bankAccount': bankAccount,
      'accountName': accountName,
      'status': 'pending',
      'type': 'withdrawal',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Notify Admins and admin@system.com
    try {
      final adminsSnap = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'ADMIN')
          .get();
          
      final rootAdminSnap = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'admin@system.com')
          .limit(1)
          .get();
      
      final hostDoc = await _firestore.collection('users').doc(hostId).get();
      final hostName = hostDoc.data()?['fullName'] ?? hostDoc.data()?['displayName'] ?? 'Một Host';

      Set<String> adminUids = adminsSnap.docs.map((doc) => doc.id).toSet();
      if (rootAdminSnap.docs.isNotEmpty) {
        adminUids.add(rootAdminSnap.docs.first.id);
      }

      for (var adminId in adminUids) {
        await NotificationService().createNotification(
          recipientId: adminId,
          title: 'Yêu cầu rút tiền mới',
          body: '$hostName vừa yêu cầu rút ${amount.toStringAsFixed(0)}đ',
          type: 'withdrawal',
          relatedId: docRef.id,
        );
      }
    } catch (e) {
      print('Failed to notify admins: $e');
    }
  }

  /// Create a USER REFUND request (when a paid PAYOS booking is cancelled).
  Future<String> createRefundRequest({
    required String userId,
    required String bookingId,
    required double amount,
    required String bankCode,
    required String bankAccount,
    required String accountName,
  }) async {
    if (amount <= 0) throw Exception('Số tiền không hợp lệ');

    final batch = _firestore.batch();

    final docRef = _firestore.collection('withdrawal_requests').doc();
    batch.set(docRef, {
      'hostId': userId,  // reuse hostId field for the requester's UID
      'bookingId': bookingId,
      'amount': amount,
      'bankCode': bankCode,
      'bankAccount': bankAccount,
      'accountName': accountName,
      'status': 'pending',
      'type': 'refund',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Mark booking refundStatus = pending
    final bookingRef = _firestore.collection('bookings').doc(bookingId);
    batch.update(bookingRef, {
      'refundStatus': 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Notify Admins and admin@system.com
    try {
      final adminsSnap = await _firestore.collection('users').where('role', isEqualTo: 'ADMIN').get();
      final rootAdminSnap = await _firestore.collection('users').where('email', isEqualTo: 'admin@system.com').limit(1).get();
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName = userDoc.data()?['fullName'] ?? userDoc.data()?['displayName'] ?? 'Khách hàng';

      Set<String> adminUids = adminsSnap.docs.map((doc) => doc.id).toSet();
      if (rootAdminSnap.docs.isNotEmpty) {
        adminUids.add(rootAdminSnap.docs.first.id);
      }

      for (var adminId in adminUids) {
        await NotificationService().createNotification(
          recipientId: adminId,
          title: 'Yêu cầu hoàn tiền mới',
          body: '$userName yêu cầu hoàn ${amount.toStringAsFixed(0)}đ (Booking đã hủy)',
          type: 'withdrawal',
          relatedId: docRef.id,
        );
      }
    } catch (e) {
      print('Failed to notify admins: $e');
    }

    return docRef.id;
  }

  Future<void> updateRequestStatus(String requestId, String newStatus, {String? rejectionReason}) async {
    final Map<String, dynamic> updateData = {
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (rejectionReason != null) {
      updateData['rejectionReason'] = rejectionReason;
    }

    await _firestore.collection('withdrawal_requests').doc(requestId).update(updateData);

    // Notify requester about status update
    try {
      final reqDoc = await _firestore.collection('withdrawal_requests').doc(requestId).get();
      if (reqDoc.exists) {
        final data = reqDoc.data()!;
        final requesterId = data['hostId']; // works for both withdrawal and refund
        final amount = data['amount'];
        final isRefund = data['type'] == 'refund';
        final bookingId = data['bookingId'];

        // If rejected and it's a refund, rollback booking refundStatus
        if (newStatus == 'rejected' && isRefund && bookingId != null) {
          await _firestore.collection('bookings').doc(bookingId).update({
            'refundStatus': 'rejected',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        if (newStatus == 'approved' && isRefund && bookingId != null) {
          await _firestore.collection('bookings').doc(bookingId).update({
            'refundStatus': 'approved',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        final typeLabel = isRefund ? 'hoàn tiền' : 'rút';
        String statusText = newStatus == 'approved' ? 'đã ĐƯỢC DUYỆT' : 'đã BỊ TỪ CHỐI';
        String reasonText = rejectionReason != null ? '\nLý do: $rejectionReason' : '';
        await NotificationService().createNotification(
          recipientId: requesterId,
          title: 'Cập nhật yêu cầu $typeLabel tiền',
          body: 'Yêu cầu $typeLabel ${amount?.toStringAsFixed(0)}đ của bạn $statusText$reasonText',
          type: 'withdrawal',
          relatedId: requestId,
        );
      }
    } catch (e) {
      print('Failed to notify requester: $e');
    }
  }

  Future<double> getAvailableBalance(String hostId) async {
    // Balance = (sum of completed bookings total price) - (sum of approved/pending withdrawals)
    try {
      final bookingsSnap = await _firestore
          .collection('bookings')
          .where('hostId', isEqualTo: hostId)
          .where('status', isEqualTo: 'completed')
          .get();
      
      double totalEarned = 0;
      for (var doc in bookingsSnap.docs) {
        final data = doc.data();
        if (data['paymentMethod'] == 'PAYOS') {
          totalEarned += (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
        }
      }

      final requestsSnap = await _firestore
          .collection('withdrawal_requests')
          .where('hostId', isEqualTo: hostId)
          .where('status', whereIn: ['pending', 'approved'])
          .get();

      double totalWithdrawn = 0;
      for (var doc in requestsSnap.docs) {
        totalWithdrawn += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
      }

      return (totalEarned - totalWithdrawn).clamp(0.0, double.infinity);
    } catch (e) {
      return 0.0;
    }
  }

  Future<Map<String, double>> getHostRevenueStats(String hostId) async {
    try {
      final bookingsSnap = await _firestore
          .collection('bookings')
          .where('hostId', isEqualTo: hostId)
          .where('status', isEqualTo: 'completed')
          .get();

      double totalRevenue = 0;
      double payosRevenue = 0;

      for (var doc in bookingsSnap.docs) {
        final data = doc.data();
        final amount = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
        totalRevenue += amount;
        if (data['paymentMethod'] == 'PAYOS') {
          payosRevenue += amount;
        }
      }

      final requestsSnap = await _firestore
          .collection('withdrawal_requests')
          .where('hostId', isEqualTo: hostId)
          .where('status', whereIn: ['pending', 'approved'])
          .get();

      double totalWithdrawn = 0;
      for (var doc in requestsSnap.docs) {
        totalWithdrawn += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
      }

      final availableBalance = (payosRevenue - totalWithdrawn).clamp(0.0, double.infinity);

      return {
        'totalRevenue': totalRevenue,    // All CASH + PAYOS
        'payosRevenue': payosRevenue,    // Only PAYOS
        'totalWithdrawn': totalWithdrawn, // All pending + approved withdraws
        'availableBalance': availableBalance, // Balance in platform
      };
    } catch (e) {
      return {
        'totalRevenue': 0.0,
        'payosRevenue': 0.0,
        'totalWithdrawn': 0.0,
        'availableBalance': 0.0,
      };
    }
  }
}
