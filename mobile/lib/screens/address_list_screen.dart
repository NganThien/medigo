import 'package:flutter/material.dart';

import '../services/address_service.dart';
import 'add_address_screen.dart';
import 'update_address_screen.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  List<Map<String, dynamic>> get _addresses => AddressService.getAddresses();
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    if (_addresses.isEmpty) {
      selectedIndex = 0;
      return;
    }
    selectedIndex = AddressService.selectedIndex.clamp(0, _addresses.length - 1);
  }

  String _formatAddress(Map<String, dynamic> item) {
    final parts = <String>[
      (item['street'] as String? ?? '').trim(),
      (item['ward'] as String? ?? '').trim(),
      (item['province'] as String? ?? '').trim(),
    ].where((part) => part.isNotEmpty).toList();
    return parts.join(', ');
  }

  Future<void> _openAddAddress() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddAddressScreen()),
    );
    if (result == true) {
      setState(() {
        selectedIndex = AddressService.selectedIndex.clamp(0, _addresses.length - 1);
      });
    }
  }

  Future<void> _openUpdateAddress(int index) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UpdateAddressScreen(
          addressIndex: index,
          initialData: _addresses[index],
        ),
      ),
    );
    if (result == true) {
      setState(() {
        if (_addresses.isEmpty) {
          selectedIndex = 0;
        } else if (selectedIndex >= _addresses.length) {
          selectedIndex = _addresses.length - 1;
        }
      });
    }
  }

  void _selectAddress(int index) {
    if (index < 0 || index >= _addresses.length) return;
    setState(() {
      selectedIndex = index;
    });
  }

  void _confirmSelectedAddress() {
    if (_addresses.isEmpty) return;
    AddressService.selectedIndex = selectedIndex;
    Navigator.pop(context, _addresses[selectedIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Địa chỉ giao hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _addresses.length,
        itemBuilder: (context, index) {
          final item = _addresses[index];
          final isSelected = selectedIndex == index;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _selectAddress(index),
            child: Card(
              color: Colors.white,
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected ? Colors.teal : Colors.transparent,
                  width: 1.2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${item['fullName']} | ${item['phone']}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(top: 4, right: 4),
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.teal,
                              size: 20,
                            ),
                          ),
                        TextButton(
                          onPressed: () => _openUpdateAddress(index),
                          child: const Text(
                            'Cập nhật',
                            style: TextStyle(color: Colors.teal),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatAddress(item),
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item['label'] as String,
                            style: const TextStyle(
                              color: Colors.teal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if ((item['isDefault'] as bool))
                          const Text(
                            '[Mặc định]',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _addresses.isEmpty ? null : _confirmSelectedAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Xác nhận',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _openAddAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Thêm địa chỉ mới',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
