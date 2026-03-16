import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/host_request_model.dart';
import '../../services/host_request_service.dart';
import '../../widgets/common/address_picker_sheet.dart';

class BecomeHostScreen extends StatefulWidget {
  final UserModel userModel;
  final HostRequestModel? existingRequest;

  const BecomeHostScreen({
    super.key,
    required this.userModel,
    this.existingRequest,
  });

  @override
  State<BecomeHostScreen> createState() => _BecomeHostScreenState();
}

class _BecomeHostScreenState extends State<BecomeHostScreen> {
  final _formKey = GlobalKey<FormState>();
  final HostRequestService _hostRequestService = HostRequestService();

  late TextEditingController _businessNameController;
  late TextEditingController _citizenIdController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(
      text: widget.existingRequest?.businessName ?? '',
    );
    _citizenIdController = TextEditingController(
      text: widget.existingRequest?.citizenId ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.existingRequest?.phone ?? widget.userModel.phoneNumber ?? '',
    );
    _addressController = TextEditingController(
      text: widget.existingRequest?.address ?? widget.userModel.address ?? '',
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _citizenIdController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final request = HostRequestModel(
        id: widget.existingRequest?.id ?? '', // empty if new
        userId: widget.userModel.uid,
        businessName: _businessNameController.text.trim(),
        citizenId: _citizenIdController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        status: 'pending',
        createdAt: widget.existingRequest?.createdAt ?? DateTime.now(),
      );

      if (widget.existingRequest != null) {
        await _hostRequestService.updateRequest(request);
      } else {
        await _hostRequestService.submitRequest(request);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gửi yêu cầu thành công! Admin sẽ duyệt sớm nhất.'),
          ),
        );
        Navigator.pop(context, true); // Return true to refresh UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi gửi yêu cầu: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text(
          'Đăng ký đối tác',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.existingRequest?.status == 'pending') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_top, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Yêu cầu của bạn đang chờ Admin xét duyệt. Bạn không thể chỉnh sửa lúc này.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Center(
                  child: Text('Vui lòng chờ phê duyệt',
                      style: TextStyle(color: Colors.white54)),
                ),
              ] else ...[
              if (widget.existingRequest?.status == 'rejected') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Yêu cầu trước đó bị từ chối.\nLý do: ${widget.existingRequest?.note ?? 'Không rõ'}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              const Text(
                'Thông tin định danh',
                style: TextStyle(
                  color: Color(0xFFD4A853),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Business Name
              TextFormField(
                controller: _businessNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Tên Khách sạn / Nhà trọ',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: Icon(
                    Icons.store,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),

              // Citizen ID
              TextFormField(
                controller: _citizenIdController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số CCCD / CMND',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: Icon(
                    Icons.branding_watermark,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập CCCD/CMND';
                  final cleaned = v.trim();
                  // Valid Vietnamese ID: 9 digits (CMND) or 12 digits (CCCD), numeric only
                  if (!RegExp(r'^\d{9}$').hasMatch(cleaned) &&
                      !RegExp(r'^\d{12}$').hasMatch(cleaned)) {
                    return 'CCCD phải gồm 12 chữ số, CMND phải gồm 9 chữ số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              const Text(
                'Thông tin liên lạc',
                style: TextStyle(
                  color: Color(0xFFD4A853),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: Icon(
                    Icons.phone,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập SĐT';
                  final cleaned = v.trim().replaceAll(RegExp(r'\s+'), '');
                  if (!RegExp(r'^0\d{9}$').hasMatch(cleaned)) {
                    return 'SĐT phải gồm 10 chữ số, bắt đầu bằng 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                readOnly: true,
                onTap: () {
                  AddressPickerSheet.show(
                    context,
                    initialAddress: _addressController.text,
                    onAddressSelected: (String newAddress) {
                      setState(() {
                        _addressController.text = newAddress;
                      });
                    },
                  );
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Địa chỉ kinh doanh',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: Icon(
                    Icons.location_on,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  suffixIcon: Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Vui lòng chọn địa chỉ'
                    : null,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4A853),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.existingRequest?.status == 'rejected'
                              ? 'Gửi lại yêu cầu'
                              : 'Gửi yêu cầu',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              ] // close 'else' block for non-pending state
            ],
          ),
        ),
      ),
    );
  }
}
