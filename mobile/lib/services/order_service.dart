import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../configs.dart';

class OrderService {
  static final List<Map<String, dynamic>> _orders = [];
  static int? _currentUserId;

  static String get baseUrl => Configs.baseUrl;

  // 🟢 HÀM BẢO MẬT: Lấy Token từ máy và kẹp vào Header
  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<void> init(int userId) async {
    _currentUserId = userId;
    await loadOrders(); 
  }

  static Future<void> loadOrders() async {
    if (_currentUserId == null) return;

    try {
      final headers = await _getAuthHeaders(); // 🟢 Dùng Header bảo mật
      final response = await http.post(
        Uri.parse('$baseUrl/orders/history'),
        headers: headers,
        body: jsonEncode({'user_id': _currentUserId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List ordersData = data['orders']; 

        _orders.clear();
        _orders.addAll(ordersData.cast<Map<String, dynamic>>());
        print('✅ Tải thành công ${ordersData.length} đơn hàng từ MySQL!');
      } else {
        print('❌ Lỗi lấy đơn hàng: ${response.body}');
      }
    } catch (e) {
      print('❌ Lỗi kết nối Server: $e');
    }
  }

  static Future<bool> addOrder(Map<String, dynamic> orderData) async {
    if (_currentUserId == null) return false;

    try {
      final headers = await _getAuthHeaders(); // 🟢 Dùng Header bảo mật

      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: headers,
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 201) {
        print('✅ Đặt hàng lên Database thành công!');
        await loadOrders(); 
        return true;
      } else {
        print('❌ Lỗi tạo đơn: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Lỗi kết nối Server khi tạo đơn: $e');
      return false;
    }
  }

  static List<Map<String, dynamic>> getAllOrders() {
    return List<Map<String, dynamic>>.from(_orders);
  }

  static void clearData() async {
    _orders.clear();
    _currentUserId = null;
    
    // Xóa token khi đăng xuất
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}