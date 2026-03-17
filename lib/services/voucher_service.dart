import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/voucher_model.dart';
import '../models/voucher_redemption_model.dart';

class VoucherService {
  final _db = FirebaseFirestore.instance;
  final _rand = Random.secure();

  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  // Removed confusing chars: I, O, 0, 1

  // ---------- Validation ----------

  /// Validates a voucher code for a given context and returns the voucher if valid.
  /// Returns null (instead of throwing) so callers can show an inline error message.
  Future<VoucherModel?> validateVoucher(
    String code, {
    required String hostId,
    required double subtotal,
    required String userId,
  }) async {
    final snap = await _db
        .collection('vouchers')
        .where('code', isEqualTo: code.toUpperCase())
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final voucher = VoucherModel.fromMap(snap.docs.first.data(), snap.docs.first.id);

    // Validity window + active flag
    if (!voucher.isValid) return null;

    // Scope: HOST voucher must match the room's hostId
    if (voucher.scope == 'HOST' && voucher.hostId != hostId) return null;

    // Min subtotal
    final requiredByDiscountAmount = () {
      // Ensure booking value is at least the voucher's discount amount/cap.
      // Example: FIXED 50,000 => subtotal must be >= 50,000
      // For PERCENT: if maxDiscount is set, subtotal must be >= maxDiscount
      if (voucher.type == 'FIXED') return voucher.value;
      if (voucher.type == 'PERCENT') return voucher.maxDiscount ?? 0.0;
      return 0.0;
    }();

    final effectiveMinSubtotal = [
      voucher.minSubtotal,
      requiredByDiscountAmount,
    ].reduce((a, b) => a > b ? a : b);

    if (subtotal < effectiveMinSubtotal) return null;

    // Per-user usage limit
    final userUsage = await _db
        .collection('voucher_redemptions')
        .where('voucherId', isEqualTo: voucher.id)
        .where('userId', isEqualTo: userId)
        .get();
    if (userUsage.docs.length >= voucher.usageLimitPerUser) return null;

    // Total usage limit
    final totalUsage = await _db
        .collection('voucher_redemptions')
        .where('voucherId', isEqualTo: voucher.id)
        .get();
    if (totalUsage.docs.length >= voucher.usageLimitTotal) return null;

    return voucher;
  }

  // ---------- Redemption ----------

  Future<void> redeemVoucher({
    required String voucherId,
    required String userId,
    required String bookingId,
  }) async {
    final redemption = VoucherRedemptionModel(
      id: '',
      voucherId: voucherId,
      userId: userId,
      bookingId: bookingId,
      createdAt: DateTime.now(),
    );
    await _db.collection('voucher_redemptions').add(redemption.toMap());
  }

  // ---------- CRUD ----------

  /// Generates a random voucher code and ensures it is unique by checking Firestore.
  Future<String> generateUniqueVoucherCode({int length = 10}) async {
    for (int attempt = 0; attempt < 20; attempt++) {
      final code = List.generate(
        length,
        (_) => _alphabet[_rand.nextInt(_alphabet.length)],
      ).join();

      final exists = await _db
          .collection('vouchers')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      if (exists.docs.isEmpty) return code;
    }
    throw Exception('Không thể tạo mã voucher duy nhất, vui lòng thử lại');
  }

  /// Creates a voucher and auto-generates a random unique `code` (ignores input code).
  Future<String> createVoucherWithRandomCode(VoucherModel voucher) async {
    final code = await generateUniqueVoucherCode();
    final ref = await _db.collection('vouchers').add({
      ...voucher.toMap(),
      'code': code,
    });
    return ref.id;
  }

  Future<String> createVoucher(VoucherModel voucher) async {
    final ref = await _db.collection('vouchers').add(voucher.toMap());
    return ref.id;
  }

  Future<void> updateVoucher(VoucherModel voucher) async {
    await _db
        .collection('vouchers')
        .doc(voucher.id)
        .update({...voucher.toMap(), 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> toggleActive(String voucherId, bool isActive) async {
    await _db.collection('vouchers').doc(voucherId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteVoucher(String voucherId) async {
    await _db.collection('vouchers').doc(voucherId).delete();
  }

  // ---------- Queries ----------

  /// Stream vouchers created by a specific host (scope=HOST, hostId={uid})
  Stream<List<VoucherModel>> getVouchersByHost(String hostId) {
    return _db
        .collection('vouchers')
        .where('scope', isEqualTo: 'HOST')
        .where('hostId', isEqualTo: hostId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => VoucherModel.fromMap(d.data(), d.id)).toList());
  }

  /// Stream active vouchers (any scope). Caller can additionally filter by `voucher.isValid`.
  Stream<List<VoucherModel>> getActiveVouchers() {
    return _db
        .collection('vouchers')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => VoucherModel.fromMap(d.data(), d.id)).toList());
  }

  /// Stream active vouchers for a host (scope=HOST, hostId={uid}).
  Stream<List<VoucherModel>> getActiveVouchersByHost(String hostId) {
    return _db
        .collection('vouchers')
        .where('scope', isEqualTo: 'HOST')
        .where('hostId', isEqualTo: hostId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => VoucherModel.fromMap(d.data(), d.id)).toList());
  }

  /// Stream all vouchers (admin only)
  Stream<List<VoucherModel>> getAllVouchers() {
    return _db
        .collection('vouchers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => VoucherModel.fromMap(d.data(), d.id)).toList());
  }

  /// Stream only global vouchers (scope=GLOBAL, admin created)
  Stream<List<VoucherModel>> getGlobalVouchers() {
    return _db
        .collection('vouchers')
        .where('scope', isEqualTo: 'GLOBAL')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => VoucherModel.fromMap(d.data(), d.id)).toList());
  }

  /// Stream only active global vouchers (scope=GLOBAL).
  Stream<List<VoucherModel>> getActiveGlobalVouchers() {
    return _db
        .collection('vouchers')
        .where('scope', isEqualTo: 'GLOBAL')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => VoucherModel.fromMap(d.data(), d.id)).toList());
  }
}
