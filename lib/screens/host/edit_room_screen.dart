import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/room_model.dart';
import '../../services/room_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_text_field.dart';

class EditRoomScreen extends StatefulWidget {
  final RoomModel? existingRoom;

  const EditRoomScreen({super.key, this.existingRoom});

  @override
  State<EditRoomScreen> createState() => _EditRoomScreenState();
}

class _EditRoomScreenState extends State<EditRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final RoomService _roomService = RoomService();
  final StorageService _storageService = StorageService();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;

  String _status = 'available';
  final List<String> _amenities = [];

  final List<String> _existingImages = [];
  final List<File> _newImages = [];

  bool _isLoading = false;

  final Map<String, String> _availableAmenities = {
    'wifi': 'Wi-Fi miễn phí',
    'ac': 'Điều hòa',
    'tv': 'TV',
    'pool': 'Hồ bơi',
    'kitchen': 'Bếp',
    'parking': 'Chỗ để xe',
    'washing_machine': 'Máy giặt',
    'breakfast': 'Ăn sáng',
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingRoom?.title ?? '',
    );
    _descController = TextEditingController(
      text: widget.existingRoom?.description ?? '',
    );
    final price = widget.existingRoom?.basePrice.toInt().toString() ?? '';
    _priceController = TextEditingController(text: price);
    _quantityController = TextEditingController(
      text: widget.existingRoom?.quantity.toString() ?? '1',
    );

    if (widget.existingRoom != null) {
      _status = widget.existingRoom!.status;
      _amenities.addAll(widget.existingRoom!.amenities);
      _existingImages.addAll(widget.existingRoom!.images);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newImages.addAll(pickedFiles.map((x) => File(x.path)));
      });
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _toggleAmenity(String key) {
    setState(() {
      if (_amenities.contains(key)) {
        _amenities.remove(key);
      } else {
        _amenities.add(key);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_existingImages.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 hình ảnh.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Upload new images if any
      List<String> uploadedUrls = [];
      for (var file in _newImages) {
        final url = await _storageService.uploadImageToCloudinary(file);
        if (url != null) {
          uploadedUrls.add(url);
        }
      }

      // 2. Combine all images
      final finalImages = [..._existingImages, ...uploadedUrls];

      // 3. Create or update model
      final roomModel = RoomModel(
        id:
            widget.existingRoom?.id ??
            '', // RoomService assigns ID on create implicitly inside collection().add(), so keep empty here (or use document Ref)
        hostId: user.uid,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        images: finalImages,
        basePrice: double.parse(_priceController.text.trim()),
        status: _status,
        quantity: int.parse(_quantityController.text.trim()),
        amenities: _amenities,
        createdAt: widget.existingRoom?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existingRoom == null) {
        await _roomService.createRoom(roomModel);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tạo phòng thành công')));
      } else {
        await _roomService.updateRoom(roomModel);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật phòng thành công')),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingRoom != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Sửa thông tin phòng' : 'Thêm phòng mới',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4A853)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Images ---
                    const Text(
                      'Hình ảnh phòng (Bắt buộc)',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white24,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.add_a_photo,
                                  color: Colors.white54,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ..._existingImages.asMap().entries.map(
                            (e) => _buildExistingImageThumb(e.key, e.value),
                          ),
                          ..._newImages.asMap().entries.map(
                            (e) => _buildNewImageThumb(e.key, e.value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Basics ---
                    CustomTextField(
                      controller: _titleController,
                      label: 'Tên phòng',
                      hint: 'VD: Phòng Đôi Deluxe',
                      prefixIcon: Icons.king_bed,
                    ),
                    const SizedBox(height: 16),
                    // For the description, CustomTextField does not support maxLines yet, so we use a standard TextField wrapped carefully.
                    _buildMultilineTextField(
                      'Mô tả phòng',
                      'Mô tả diện tích, tầm nhìn...',
                      _descController,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _priceController,
                            label: 'Giá / Giờ (VND)',
                            hint: 'VD: 50000',
                            prefixIcon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _quantityController,
                            label: 'Số lượng phòng',
                            hint: 'VD: 5',
                            prefixIcon: Icons.format_list_numbered,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Status ---
                    const Text(
                      'Trạng thái',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _status,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1A1A1A),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white54,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'available',
                              child: Text('Sẵn sàng'),
                            ),
                            DropdownMenuItem(
                              value: 'maintenance',
                              child: Text('Bảo trì'),
                            ),
                            DropdownMenuItem(
                              value: 'unavailable',
                              child: Text('Ngưng hoạt động'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _status = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Amenities ---
                    const Text(
                      'Tiện ích',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableAmenities.entries.map((entry) {
                        final isSelected = _amenities.contains(entry.key);
                        return ChoiceChip(
                          label: Text(entry.value),
                          selected: isSelected,
                          selectedColor: const Color(
                            0xFFD4A853,
                          ).withOpacity(0.2),
                          backgroundColor: const Color(0xFF1A1A1A),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? const Color(0xFFD4A853)
                                : Colors.white54,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFFD4A853)
                                  : Colors.transparent,
                            ),
                          ),
                          onSelected: (_) => _toggleAmenity(entry.key),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),

                    // --- Save Button ---
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4A853),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isEditing ? 'Lưu thay đổi' : 'Tạo phòng',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildExistingImageThumb(int index, String url) {
    return _buildThumbWrapper(
      child: Image.network(url, fit: BoxFit.cover),
      onRemove: () => _removeExistingImage(index),
    );
  }

  Widget _buildNewImageThumb(int index, File file) {
    return _buildThumbWrapper(
      child: Image.file(file, fit: BoxFit.cover),
      onRemove: () => _removeNewImage(index),
    );
  }

  Widget _buildThumbWrapper({
    required Widget child,
    required VoidCallback onRemove,
  }) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: child,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultilineTextField(
    String label,
    String hint,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          validator: (val) =>
              val == null || val.trim().isEmpty ? 'Không được để trống' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
