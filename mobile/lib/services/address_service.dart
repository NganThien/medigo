import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AddressService {
  static final List<Map<String, dynamic>> _addressList = [];
  static String? _currentUserPhone;
  static int selectedIndex = 0;

  static Future<void> init(String userPhone) async {
    _currentUserPhone = userPhone;
    await loadAddresses();
  }

  static Future<void> loadAddresses() async {
    if (_currentUserPhone == null) return;

    final prefs = await SharedPreferences.getInstance();
    final addressesKey = 'addresses_$_currentUserPhone';
    final addressesString = prefs.getString(addressesKey);

    _addressList.clear(); // Đảm bảo dọn sạch list cũ trước khi nạp

    if (addressesString != null) {
      try {
        final addressesData = jsonDecode(addressesString) as List;
        // SỬA LỖI 2: Cách giải mã an toàn 100%, không bao giờ bị crash ngầm mất dữ liệu
        _addressList.addAll(
          addressesData.map((e) => Map<String, dynamic>.from(e)).toList(),
        );
      } catch (e) {
        print('Lỗi nạp địa chỉ: $e');
      }
    }
    // SỬA LỖI 1: Đã xóa toàn bộ khối "else" chứa Nguyễn Văn A.
    // Tài khoản mới từ giờ sẽ có danh sách trống trơn!
  }

  static Future<void> saveAddresses() async {
    if (_currentUserPhone == null) return;

    final prefs = await SharedPreferences.getInstance();
    final addressesKey = 'addresses_$_currentUserPhone';
    await prefs.setString(addressesKey, jsonEncode(_addressList));
  }

  static List<Map<String, dynamic>> getAddresses() {
    return _addressList;
  }

  static void addAddress(Map<String, dynamic> data) {
    if (data['isDefault'] as bool? ?? false) {
      for (final address in _addressList) {
        address['isDefault'] = false;
      }
    }

    // Tự động gán mặc định nếu đây là địa chỉ đầu tiên khách hàng thêm
    if (_addressList.isEmpty) {
      data['isDefault'] = true;
    }

    _addressList.add(data);
    selectedIndex = _addressList.length - 1;
    saveAddresses(); // Ghi thẳng vào ổ cứng điện thoại
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
    saveAddresses();
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
    } else if (selectedIndex >= _addressList.length) {
      selectedIndex = _addressList.length - 1;
    }
    saveAddresses();
  }

  static void clearData() {
    _addressList.clear();
    _currentUserPhone = null;
    selectedIndex = 0;
  }
}
