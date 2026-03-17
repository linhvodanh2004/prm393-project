import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/host_request_model.dart';
import '../../services/host_request_service.dart';
import '../../DTOs/submit_host_request_dto.dart';
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
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late TextEditingController _taxCodeController;

  String _businessType = 'private'; // 'private' or 'business'
  int _businessStartYear = DateTime.now().year;
  bool _isSubmitting = false;

  static const int _minYear = 1900;

  @override
  void initState() {
    super.initState();
    final req = widget.existingRequest;
    _businessNameController = TextEditingController(
      text: req?.businessName ?? '',
    );
    _phoneController = TextEditingController(
      text: req?.phone ?? widget.userModel.phoneNumber ?? '',
    );
    _addressController = TextEditingController(
      text: req?.address ?? widget.userModel.address ?? '',
    );
    _descriptionController = TextEditingController(
      text: req?.description ?? '',
    );
    _taxCodeController = TextEditingController(
      text: req?.taxCode ?? '',
    );
    _businessType = req?.businessType ?? 'private';
    _businessStartYear = req?.businessStartYear ?? DateTime.now().year;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _taxCodeController.dispose();
    super.dispose();
  }

  // ─── Terms Dialog ────────────────────────────────────────────────────────────
  Future<bool> _showTermsDialog() async {
    bool agreed = false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Điều khoản đối tác',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      _termsContent,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => setDialogState(() => agreed = !agreed),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: agreed,
                        onChanged: (v) =>
                            setDialogState(() => agreed = v ?? false),
                        activeColor: const Color(0xFFD4A853),
                        side: const BorderSide(color: Colors.white38),
                      ),
                      const Expanded(
                        child: Text(
                          'Tôi đã đọc và đồng ý với các điều khoản trên',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Huỷ',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: agreed ? () => Navigator.pop(ctx, true) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A853),
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Xác nhận & Gửi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  // ─── Submit ──────────────────────────────────────────────────────────────────
  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await _showTermsDialog();
    if (!confirmed) return;

    setState(() => _isSubmitting = true);

    try {
      if (widget.existingRequest != null) {
        // Resubmit: build a model from existing and update
        final request = HostRequestModel(
          id: widget.existingRequest!.id,
          userId: widget.userModel.uid,
          businessName: _businessNameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          description: _descriptionController.text.trim(),
          businessStartYear: _businessStartYear,
          businessType: _businessType,
          taxCode: _businessType == 'business'
              ? _taxCodeController.text.trim()
              : null,
          status: 'pending',
          createdAt: widget.existingRequest!.createdAt,
        );
        await _hostRequestService.updateRequest(request);
      } else {
        final dto = SubmitHostRequestDTO(
          userId: widget.userModel.uid,
          businessName: _businessNameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          description: _descriptionController.text.trim(),
          businessStartYear: _businessStartYear,
          businessType: _businessType,
          taxCode: _businessType == 'business'
              ? _taxCodeController.text.trim()
              : null,
        );
        await _hostRequestService.submitRequest(dto);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gửi yêu cầu thành công! Admin sẽ duyệt sớm nhất.'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi gửi yêu cầu: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isPending = widget.existingRequest?.status == 'pending';
    final isRejected = widget.existingRequest?.status == 'rejected';

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
        child: isPending
            ? _buildPendingView()
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isRejected) _buildRejectedBanner(),
                    _sectionHeader('Thông tin cơ sở'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _businessNameController,
                      label: 'Tên Khách sạn / Nhà trọ',
                      icon: Icons.store,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Vui lòng nhập tên' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Mô tả cơ sở',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Vui lòng nhập mô tả'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildYearPicker(),
                    const SizedBox(height: 32),
                    _sectionHeader('Loại hình kinh doanh'),
                    const SizedBox(height: 12),
                    _buildBusinessTypeSelector(),
                    if (_businessType == 'business') ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _taxCodeController,
                        label: 'Mã số thuế',
                        icon: Icons.receipt_long_outlined,
                        validator: (v) {
                          if (_businessType != 'business') return null;
                          if (v == null || v.trim().isEmpty) {
                            return 'Vui lòng nhập mã số thuế';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    _sectionHeader('Thông tin liên lạc'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Số điện thoại',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Vui lòng nhập SĐT';
                        }
                        final cleaned =
                            v.trim().replaceAll(RegExp(r'\s+'), '');
                        if (!RegExp(r'^0\d{9}$').hasMatch(cleaned)) {
                          return 'SĐT phải gồm 10 chữ số, bắt đầu bằng 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildAddressField(),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── Sub-widgets ─────────────────────────────────────────────────────────────

  Widget _buildPendingView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: const Column(
        children: [
          Icon(Icons.hourglass_top, color: Colors.orange, size: 48),
          SizedBox(height: 16),
          Text(
            'Yêu cầu đang chờ duyệt',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Admin sẽ xem xét và phê duyệt yêu cầu của bạn sớm nhất có thể. Bạn không thể chỉnh sửa lúc này.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedBanner() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
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
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFD4A853),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: validator,
    );
  }

  Widget _buildYearPicker() {
    final currentYear = DateTime.now().year;
    return DropdownButtonFormField<int>(
      value: _businessStartYear,
      dropdownColor: const Color(0xFF1A1A1A),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Năm bắt đầu kinh doanh',
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon:
            Icon(Icons.calendar_today, color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: List.generate(
        currentYear - _minYear + 1,
        (i) => currentYear - i,
      ).map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
      onChanged: (v) => setState(() => _businessStartYear = v ?? currentYear),
    );
  }

  Widget _buildBusinessTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _typeCard(
            label: 'Cá nhân',
            subtitle: 'Hộ kinh doanh cá thể',
            icon: Icons.person_outline,
            value: 'private',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _typeCard(
            label: 'Doanh nghiệp',
            subtitle: 'Có mã số thuế',
            icon: Icons.business_outlined,
            value: 'business',
          ),
        ),
      ],
    );
  }

  Widget _typeCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final selected = _businessType == value;
    return GestureDetector(
      onTap: () => setState(() => _businessType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFD4A853).withOpacity(0.12)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFFD4A853)
                : Colors.white.withOpacity(0.1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFFD4A853) : Colors.white38,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFFD4A853) : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      readOnly: true,
      onTap: () {
        AddressPickerSheet.show(
          context,
          initialAddress: _addressController.text,
          onAddressSelected: (String newAddress) {
            setState(() => _addressController.text = newAddress);
          },
        );
      },
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Địa chỉ kinh doanh',
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon:
            Icon(Icons.location_on, color: Colors.white.withOpacity(0.5)),
        suffixIcon:
            Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Vui lòng chọn địa chỉ' : null,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
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
                    : 'Đọc điều khoản & Gửi yêu cầu',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // ─── Terms Content ────────────────────────────────────────────────────────────
  static const String _termsContent = '''
1. Điều kiện tham gia
Đối tác phải là cá nhân hoặc tổ chức có đủ năng lực pháp lý, hoạt động hợp pháp theo quy định của pháp luật Việt Nam.

2. Cam kết thông tin
Đối tác cam kết cung cấp thông tin trung thực, chính xác và chịu trách nhiệm hoàn toàn trước pháp luật đối với các thông tin đã đăng ký.

3. Chất lượng dịch vụ
Đối tác có trách nhiệm đảm bảo chất lượng phòng, dịch vụ đúng với mô tả đã đăng ký trên hệ thống.

4. Tuân thủ quy định
Đối tác phải tuân thủ tất cả các quy định về an ninh, vệ sinh, phòng cháy chữa cháy và các quy định pháp luật có liên quan.

5. Phí dịch vụ
Đối tác đồng ý với chính sách phí và hoa hồng theo quy định của nền tảng tại từng thời điểm.

6. Điều khoản chấm dứt
Nền tảng có quyền tạm ngưng hoặc chấm dứt tư cách đối tác nếu phát hiện vi phạm điều khoản sử dụng.

7. Chấp thuận dữ liệu
Đối tác đồng ý để nền tảng lưu trữ và xử lý thông tin đăng ký theo chính sách bảo mật của chúng tôi.''';
}
