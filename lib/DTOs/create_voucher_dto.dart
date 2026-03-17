import '../models/voucher_model.dart';

/// DTO for creating a new voucher.
/// Used by [ManageVouchersScreen] → [VoucherService.createVoucherWithRandomCode].
/// Note: [code] is intentionally excluded — the service auto-generates a unique code.
class CreateVoucherDTO {
  /// Voucher scope: 'HOST' (host-specific) or 'GLOBAL' (platform-wide).
  final String scope;

  /// Required when [scope] == 'HOST'.
  final String? hostId;

  /// Discount type: 'PERCENT' or 'FIXED'.
  final String type;

  /// Percentage (0–100) for PERCENT type, or fixed VND amount for FIXED type.
  final double value;

  /// Maximum discount cap in VND (only meaningful for PERCENT type).
  final double? maxDiscount;

  /// Minimum booking subtotal required to apply this voucher.
  /// Must be >= [value] for FIXED type, or >= [maxDiscount] for PERCENT type.
  final double minSubtotal;

  final DateTime? startAt;
  final DateTime? endAt;
  final bool isActive;
  final int usageLimitTotal;
  final int usageLimitPerUser;

  /// UID of the creator (host or admin).
  final String createdBy;

  const CreateVoucherDTO({
    required this.scope,
    this.hostId,
    required this.type,
    required this.value,
    this.maxDiscount,
    this.minSubtotal = 0,
    this.startAt,
    this.endAt,
    this.isActive = true,
    this.usageLimitTotal = 9999,
    this.usageLimitPerUser = 1,
    required this.createdBy,
  });

  static const _validScopes = {'HOST', 'GLOBAL'};
  static const _validTypes = {'PERCENT', 'FIXED'};

  String? validate() {
    if (!_validScopes.contains(scope)) return 'Invalid scope: $scope';
    if (scope == 'HOST' && (hostId == null || hostId!.trim().isEmpty)) {
      return 'hostId is required for HOST-scoped vouchers';
    }
    if (!_validTypes.contains(type)) return 'Invalid type: $type';
    if (value <= 0) return 'value must be greater than 0';
    if (type == 'PERCENT' && value > 100) {
      return 'Phần trăm giảm giá không được vượt quá 100%';
    }
    if (type == 'FIXED' && minSubtotal < value) {
      return 'Giá trị đơn tối thiểu phải >= mức giảm giá ($value)';
    }
    if (type == 'PERCENT' && maxDiscount != null && minSubtotal < maxDiscount!) {
      return 'Giá trị đơn tối thiểu phải >= mức giảm tối đa ($maxDiscount)';
    }
    if (endAt != null && startAt != null && !endAt!.isAfter(startAt!)) {
      return 'Ngày kết thúc phải sau ngày bắt đầu';
    }
    return null;
  }

  VoucherModel toModel() {
    final now = DateTime.now();
    return VoucherModel(
      id: '',
      code: '',
      scope: scope,
      hostId: hostId,
      type: type,
      value: value,
      maxDiscount: maxDiscount,
      minSubtotal: minSubtotal,
      startAt: startAt,
      endAt: endAt,
      isActive: isActive,
      usageLimitTotal: usageLimitTotal,
      usageLimitPerUser: usageLimitPerUser,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
  }
}
