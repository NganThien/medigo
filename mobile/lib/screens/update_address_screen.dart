import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/address_service.dart';

class UpdateAddressScreen extends StatefulWidget {
  final int addressIndex;
  final Map<String, dynamic> initialData;

  const UpdateAddressScreen({
    super.key,
    required this.addressIndex,
    required this.initialData,
  });

  @override
  State<UpdateAddressScreen> createState() => _UpdateAddressScreenState();
}

class _UpdateAddressScreenState extends State<UpdateAddressScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _provinceController = TextEditingController();
  final _wardController = TextEditingController();
  final _streetController = TextEditingController();

  String _addressType = 'Nhà riêng';
  bool _isDefaultAddress = false;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.initialData['fullName'] as String? ?? '';
    _phoneController.text = widget.initialData['phone'] as String? ?? '';
    _provinceController.text = widget.initialData['province'] as String? ?? '';
    _wardController.text = widget.initialData['ward'] as String? ?? '';
    _streetController.text = widget.initialData['street'] as String? ?? '';
    _addressType = widget.initialData['label'] as String? ?? 'Nhà riêng';
    _isDefaultAddress = widget.initialData['isDefault'] as bool? ?? false;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _provinceController.dispose();
    _wardController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa địa chỉ'),
        content: const Text('Bạn có chắc muốn xóa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (shouldDelete == true && mounted) {
      AddressService.deleteAddress(widget.addressIndex);
      Navigator.pop(context, true);
    }
  }

  void _saveAddress() {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(() {
        _phoneError = 'Số điện thoại phải có đúng 10 chữ số';
      });
      return;
    }
    setState(() {
      _phoneError = null;
    });

    final province = _provinceController.text.trim();
    final ward = _wardController.text.trim();
    final street = _streetController.text.trim();
    final fullAddressParts = [street, ward, province]
        .where((part) => part.isNotEmpty)
        .toList();

    final updated = <String, dynamic>{
      'fullName': _fullNameController.text.trim().isEmpty
          ? 'Chưa cập nhật'
          : _fullNameController.text.trim(),
      'phone': _phoneController.text.trim().isEmpty
          ? 'Chưa cập nhật'
          : _phoneController.text.trim(),
      'province': province,
      'ward': ward,
      'street': street.isEmpty ? 'Chưa cập nhật' : street,
      'fullAddress': fullAddressParts.join(', '),
      'label': _addressType,
      'isDefault': _isDefaultAddress,
    };
    AddressService.updateAddress(widget.addressIndex, updated);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Cập nhật địa chỉ'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Họ và tên'),
                _buildInputField(
                  controller: _fullNameController,
                  hintText: 'Nhập họ và tên',
                ),
                const SizedBox(height: 12),
                _buildLabel('Số điện thoại'),
                _buildPhoneField(
                  controller: _phoneController,
                  hintText: 'Nhập số điện thoại',
                ),
                const SizedBox(height: 12),
                _buildLabel('Tỉnh / Thành phố'),
                _buildInputField(
                  controller: _provinceController,
                  hintText: 'Nhập Tỉnh / Thành phố',
                ),
                const SizedBox(height: 12),
                _buildLabel('Phường / Xã'),
                _buildInputField(
                  controller: _wardController,
                  hintText: 'Nhập Phường / Xã',
                ),
                const SizedBox(height: 12),
                _buildLabel('Địa chỉ cụ thể'),
                _buildInputField(
                  controller: _streetController,
                  hintText: 'Số nhà, tên đường...',
                ),
                const SizedBox(height: 16),
                _buildLabel('Loại địa chỉ'),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Nhà riêng'),
                      selected: _addressType == 'Nhà riêng',
                      onSelected: (_) => setState(() => _addressType = 'Nhà riêng'),
                      selectedColor: Colors.teal.withOpacity(0.2),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('Công ty'),
                      selected: _addressType == 'Công ty',
                      onSelected: (_) => setState(() => _addressType = 'Công ty'),
                      selectedColor: Colors.teal.withOpacity(0.2),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Đặt làm địa chỉ mặc định',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    Switch(
                      value: _isDefaultAddress,
                      activeColor: Colors.teal,
                      onChanged: (value) {
                        setState(() => _isDefaultAddress = value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _saveAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Lưu',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: _inputDecoration(hintText: hintText),
    );
  }

  Widget _buildPhoneField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      textInputAction: TextInputAction.done,
      onChanged: (_) {
        if (_phoneError != null && controller.text.trim().length == 10) {
          setState(() {
            _phoneError = null;
          });
        }
      },
      onFieldSubmitted: (_) => _saveAddress(),
      decoration: _inputDecoration(
        hintText: hintText,
        errorText: _phoneError,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.teal),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
