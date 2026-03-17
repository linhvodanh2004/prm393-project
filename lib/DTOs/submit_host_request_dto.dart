import '../models/host_request_model.dart';

/// DTO for submitting a "become a host" request.
/// Used by [BecomeHostScreen] → [HostRequestService.submitRequest].
class SubmitHostRequestDTO {
  final String userId;
  final String businessName;
  final String phone;
  final String address;
  final String description;
  final int businessStartYear;

  /// 'private' or 'business'
  final String businessType;

  /// Required when [businessType] == 'business'.
  final String? taxCode;

  const SubmitHostRequestDTO({
    required this.userId,
    required this.businessName,
    required this.phone,
    required this.address,
    required this.description,
    required this.businessStartYear,
    required this.businessType,
    this.taxCode,
  });

  static const _validBusinessTypes = {'private', 'business'};

  String? validate() {
    if (userId.trim().isEmpty) return 'userId is required';
    if (businessName.trim().isEmpty) return 'Tên doanh nghiệp không được để trống';
    if (phone.trim().isEmpty) return 'Số điện thoại không được để trống';
    if (address.trim().isEmpty) return 'Địa chỉ không được để trống';
    if (description.trim().isEmpty) return 'Mô tả không được để trống';
    if (businessStartYear < 1900 || businessStartYear > DateTime.now().year) {
      return 'Năm bắt đầu kinh doanh không hợp lệ';
    }
    if (!_validBusinessTypes.contains(businessType)) {
      return 'Loại hình kinh doanh không hợp lệ';
    }
    if (businessType == 'business' &&
        (taxCode == null || taxCode!.trim().isEmpty)) {
      return 'Mã số thuế bắt buộc với doanh nghiệp';
    }
    return null;
  }

  HostRequestModel toModel() {
    return HostRequestModel(
      id: '',
      userId: userId,
      businessName: businessName.trim(),
      phone: phone.trim(),
      address: address.trim(),
      description: description.trim(),
      businessStartYear: businessStartYear,
      businessType: businessType,
      taxCode: taxCode?.trim(),
      status: 'pending',
      createdAt: DateTime.now(),
    );
  }
}
