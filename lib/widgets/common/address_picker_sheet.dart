import 'package:flutter/material.dart';
import '../../models/location_models.dart';
import '../../services/location_service.dart';
import '../../utils/address_utils.dart';

class AddressPickerSheet extends StatefulWidget {
  final String? initialAddress;
  final Function(String) onAddressSelected;

  const AddressPickerSheet({
    super.key,
    this.initialAddress,
    required this.onAddressSelected,
  });

  /// Helper to easily show this bottom sheet
  static Future<void> show(
    BuildContext context, {
    String? initialAddress,
    required Function(String) onAddressSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddressPickerSheet(
          initialAddress: initialAddress,
          onAddressSelected: onAddressSelected,
        ),
      ),
    );
  }

  @override
  State<AddressPickerSheet> createState() => _AddressPickerSheetState();
}

class _AddressPickerSheetState extends State<AddressPickerSheet> {
  final LocationService _locationService = LocationService();
  final TextEditingController _streetController = TextEditingController();

  List<Province> _provinces = [];
  List<Ward> _wards = [];

  Province? _selectedProvince;
  Ward? _selectedWard;

  bool _isLoadingProvinces = true;
  bool _isLoadingWards = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Fill the street with the old address, so user doesn't lose old free-text data.
    _streetController.text = AddressUtils.extractStreetLine(
      widget.initialAddress,
    );
    _loadProvinces();
  }

  @override
  void dispose() {
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    try {
      setState(() {
        _isLoadingProvinces = true;
        _errorMessage = null;
      });
      final provinces = await _locationService.getProvinces();
      setState(() {
        _provinces = provinces;
        _isLoadingProvinces = false;
      });

      // Attempt to auto-select province
      final initProvinceName = AddressUtils.extractProvince(
        widget.initialAddress,
      );
      if (initProvinceName != null && initProvinceName.isNotEmpty) {
        try {
          final matchedProvince = provinces.firstWhere(
            (p) => p.name.toLowerCase() == initProvinceName.toLowerCase(),
          );
          _onProvinceSelected(matchedProvince, isInit: true);
        } catch (_) {
          // No match found, ignore
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải Tỉnh/Thành phố. Vui lòng thử lại.';
        _isLoadingProvinces = false;
      });
    }
  }

  Future<void> _onProvinceSelected(
    Province? province, {
    bool isInit = false,
  }) async {
    if (province == null ||
        (!isInit && province.code == _selectedProvince?.code))
      return;

    setState(() {
      _selectedProvince = province;
      if (!isInit) _selectedWard = null;
      _wards = [];
      _isLoadingWards = true;
      _errorMessage = null;
    });

    try {
      final wards = await _locationService.getWards(province.code);
      setState(() {
        _wards = wards;
        _isLoadingWards = false;
      });

      if (isInit) {
        final initWardName = AddressUtils.extractWard(widget.initialAddress);
        if (initWardName != null && initWardName.isNotEmpty) {
          try {
            final matchedWard = wards.firstWhere(
              (w) => w.name.toLowerCase() == initWardName.toLowerCase(),
            );
            setState(() {
              _selectedWard = matchedWard;
            });
          } catch (_) {
            // No match found
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải Phường/Xã.';
        _isLoadingWards = false;
      });
    }
  }

  void _submit() {
    if (_selectedProvince == null ||
        _selectedWard == null ||
        _streetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đủ thông tin địa chỉ')),
      );
      return;
    }

    final fullAddress = AddressUtils.formatAddress(
      street: _streetController.text.trim(),
      ward: _selectedWard!.name,
      province: _selectedProvince!.name,
    );

    widget.onAddressSelected(fullAddress);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn địa chỉ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),

            // Street Input
            TextField(
              controller: _streetController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Số nhà, Tên đường',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: Icon(
                  Icons.edit_road,
                  color: Colors.white.withOpacity(0.5),
                ),
                filled: true,
                fillColor: const Color(0xFF0D0D0D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Province Dropdown
            _buildDropdown<Province>(
              hint: 'Chọn Tỉnh / Thành phố',
              isLoading: _isLoadingProvinces,
              items: _provinces,
              value: _selectedProvince,
              getName: (p) => p.name,
              onChanged: _onProvinceSelected,
            ),
            const SizedBox(height: 16),

            // Ward Dropdown
            _buildDropdown<Ward>(
              hint: 'Chọn Phường / Xã',
              isLoading: _isLoadingWards,
              items: _wards,
              value: _selectedWard,
              getName: (w) => w.name,
              onChanged: (ward) => setState(() => _selectedWard = ward),
              isEnabled: _selectedProvince != null,
            ),
            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A853),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Xác nhận địa chỉ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required bool isLoading,
    required List<T> items,
    required T? value,
    required String Function(T) getName,
    required void Function(T?) onChanged,
    bool isEnabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isEnabled ? const Color(0xFF0D0D0D) : const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                hint: Text(
                  hint,
                  style: TextStyle(
                    color: Colors.white.withOpacity(isEnabled ? 0.5 : 0.2),
                  ),
                ),
                dropdownColor: const Color(0xFF1A1A1A),
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFD4A853),
                        ),
                      )
                    : Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white.withOpacity(isEnabled ? 0.5 : 0.2),
                      ),
                isExpanded: true,
                style: const TextStyle(color: Colors.white),
                onChanged: isEnabled ? onChanged : null,
                items: items.map((T item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(getName(item)),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
