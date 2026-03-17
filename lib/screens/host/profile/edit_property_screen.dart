import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/property_model.dart';
import '../../../services/property_service.dart';
import '../../../services/storage_service.dart';
import '../../../DTOs/save_property_dto.dart';
import '../../../widgets/common/address_picker_sheet.dart';

class EditPropertyScreen extends StatefulWidget {
  final PropertyModel? currentProperty;
  final String hostId;

  const EditPropertyScreen({
    Key? key,
    this.currentProperty,
    required this.hostId,
  }) : super(key: key);

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _propertyService = PropertyService();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _addressController;

  String? _coverImageUrl;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.currentProperty?.title ?? '',
    );
    _descController = TextEditingController(
      text: widget.currentProperty?.description ?? '',
    );
    _addressController = TextEditingController(
      text: widget.currentProperty?.address ?? '',
    );
    _coverImageUrl = widget.currentProperty?.coverImage;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadCover() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final String? secureUrl = await _storageService.uploadImageToCloudinary(
        File(image.path),
      );
      if (secureUrl != null) {
        setState(() => _coverImageUrl = secureUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải ảnh: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;
    if (_coverImageUrl == null || _coverImageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tải lên ảnh bìa nhà trọ')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dto = SavePropertyDTO(
        hostId: widget.hostId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        address: _addressController.text.trim(),
        coverImage: _coverImageUrl!,
        policies: widget.currentProperty?.policies ?? [],
        existingCreatedAt: widget.currentProperty?.createdAt,
      );

      await _propertyService.saveProperty(dto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật thông tin nhà trọ!')),
        );
        Navigator.pop(context, true); // true to signal a refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi lưu thông tin: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text(
          'Thông tin Nhà Trọ/Khách Sạn',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF111111),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isSaving
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4A853)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover Image Picker
                    GestureDetector(
                      onTap: _isUploadingImage ? null : _pickAndUploadCover,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                          image: _coverImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(_coverImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _isUploadingImage
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFD4A853),
                                ),
                              )
                            : _coverImageUrl == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 50,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tải ảnh bìa lên',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                alignment: Alignment.bottomRight,
                                padding: const EdgeInsets.all(8),
                                child: const CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  child: Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Inputs
                    _buildTextField(
                      controller: _titleController,
                      label: 'Tên nhà trọ / Khách sạn',
                      icon: Icons.business,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Vui lòng nhập tên nhà trọ'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Địa chỉ đầy đủ',
                      icon: Icons.location_on,
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
                      validator: (val) => val == null || val.isEmpty
                          ? 'Vui lòng chọn địa chỉ'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descController,
                      label: 'Mô tả chung',
                      icon: Icons.description,
                      maxLines: 4,
                      validator: (val) => val == null || val.isEmpty
                          ? 'Vui lòng nhập mô tả'
                          : null,
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4A853),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _saveProperty,
                        child: const Text(
                          'Lưu thông tin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: maxLines == 1 ? Icon(icon, color: Colors.blueAccent) : null,
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4A853)),
        ),
      ),
      validator: validator,
    );
  }
}
