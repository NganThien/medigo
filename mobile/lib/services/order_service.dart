import 'dart:convert';
import 'package:http/http.dart' as http;

class OrderService {
  static final List<Map<String, dynamic>> _orders = [];

  // 1. ĐỔI TỪ PHONE SANG ID ĐỂ KHỚP VỚI FLASK
  static int? _currentUserId;

  // Thay bằng IP của Flask. Nếu dùng máy ảo Android thì để 10.0.2.2, dùng máy thật thì điền IP WiFi (vd: 192.168.1.x)
  static const String baseUrl = 'http://127.0.0.1:5000/api';

  static Future<void> init(int userId) async {
    _currentUserId = userId;
    await loadOrders(); // Tự động kéo dữ liệu từ server khi đăng nhập
  }

  // --- API 6: LẤY LỊCH SỬ ĐƠN HÀNG TỪ SERVER ---
  static Future<void> loadOrders() async {
    if (_currentUserId == null) return;

    try {
      // Gọi đúng method POST theo yêu cầu của Flask
      final response = await http.post(
        Uri.parse('$baseUrl/orders/history'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': _currentUserId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List ordersData = data['orders']; // Bắt đúng mảng 'orders'

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

  // --- API 5: TẠO ĐƠN HÀNG MỚI LÊN SERVER ---
  static Future<bool> addOrder(Map<String, dynamic> orderData) async {
    if (_currentUserId == null) return false;

    try {
      // Bơm user_id vào cục data trước khi gửi đi
      orderData['user_id'] = _currentUserId;

      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 201) {
        print('✅ Đặt hàng lên Database thành công!');
        await loadOrders(); // Đặt xong lập tức gọi server lấy danh sách mới nhất về
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

  static void clearData() {
    _orders.clear();
    _currentUserId = null;
  }
}
