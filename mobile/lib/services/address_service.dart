class AddressService {
  static final List<Map<String, dynamic>> _addressList = [
    {
      'fullName': 'Nguyen Van A',
      'phone': '0901234567',
      'province': 'TP. Hồ Chí Minh',
      'district': 'Quận 1',
      'ward': 'Phường Bến Nghé',
      'street': '123 Đường ABC',
      'label': 'Nhà riêng',
      'isDefault': true,
    },
    {
      'fullName': 'Tran Thi B',
      'phone': '0912345678',
      'province': 'Đà Nẵng',
      'district': 'Quận Hải Châu',
      'ward': 'Phường Hải Châu I',
      'street': 'Tòa nhà XYZ, 12 Nguyễn Huệ',
      'label': 'Công ty',
      'isDefault': false,
    },
  ];

  static int selectedIndex = 0;

  static List<Map<String, dynamic>> getAddresses() {
    return _addressList;
  }

  static void addAddress(Map<String, dynamic> data) {
    if (data['isDefault'] as bool? ?? false) {
      for (final address in _addressList) {
        address['isDefault'] = false;
      }
    }
    _addressList.add(data);
    selectedIndex = _addressList.length - 1;
  }

  static void updateAddress(int index, Map<String, dynamic> data) {
    if (index < 0 || index >= _addressList.length) return;

    if (data['isDefault'] as bool? ?? false) {
      for (final address in _addressList) {
        address['isDefault'] = false;
      }
    }
    _addressList[index] = data;
    selectedIndex = index;
  }

  static Map<String, dynamic>? getDefaultAddress() {
    if (_addressList.isEmpty) return null;
    for (final address in _addressList) {
      if (address['isDefault'] as bool? ?? false) {
        return address;
      }
    }
    return _addressList.first;
  }

  static void deleteAddress(int index) {
    if (index < 0 || index >= _addressList.length) return;

    _addressList.removeAt(index);
    if (_addressList.isEmpty) {
      selectedIndex = 0;
      return;
    }
    if (selectedIndex >= _addressList.length) {
      selectedIndex = _addressList.length - 1;
    }
  }
}
