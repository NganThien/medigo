import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'product.dart';
import '../configs.dart'; 

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class Cart {
  static List<CartItem> items = [];
  static int? _userId;

  // 🟢 HÀM BẢO MẬT: Lấy Token từ máy và kẹp vào Header
  static Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user_data');
    if (userString != null) {
      final userData = jsonDecode(userString);
      _userId = userData['id'];
      await _fetchCartFromServer();
    }
  }

  static Future<void> _fetchCartFromServer() async {
    if (_userId == null) return;
    try {
      final headers = await _getAuthHeaders(); // 🟢
      final response = await http.get(
        Uri.parse('${Configs.baseUrl}/cart/$_userId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List cartData = data['cart'] ?? [];

        items.clear();
        for (var item in cartData) {
          if (item['product'] != null) {
            items.add(
              CartItem(
                product: Product.fromJson(item['product']),
                quantity: item['quantity'],
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Lỗi tải giỏ hàng: $e');
    }
  }

  static Future<void> addToCart(Product product, int quantity) async {
    final index = items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      items[index].quantity += quantity;
    } else {
      items.add(CartItem(product: product, quantity: quantity));
    }

    if (_userId != null) {
      try {
        final headers = await _getAuthHeaders(); // 🟢
        await http.post(
          Uri.parse('${Configs.baseUrl}/cart/add'),
          headers: headers,
          body: jsonEncode({
            'user_id': _userId,
            'product_id': int.tryParse(product.id.toString()) ?? 0,
            'quantity': quantity,
          }),
        );
      } catch (e) {
        print('Lỗi đồng bộ giỏ hàng: $e');
      }
    }
  }

  static Future<void> removeFromCart(int index) async {
    if (index < 0 || index >= items.length) return;

    final productId = items[index].product.id;
    items.removeAt(index); 

    if (_userId != null) {
      try {
        final headers = await _getAuthHeaders(); // 🟢
        await http.delete(
          Uri.parse('${Configs.baseUrl}/cart/remove/$productId'),
          headers: headers,
        );
      } catch (e) {
        print('Lỗi xóa DB: $e');
      }
    }
  }

  static Future<void> clearCart() async {
    items.clear();
    if (_userId != null) {
      try {
        final headers = await _getAuthHeaders(); // 🟢
        await http.delete(
          Uri.parse('${Configs.baseUrl}/cart/clear'),
          headers: headers,
        );
      } catch (e) {
        print('Lỗi clear DB: $e');
      }
    }
  }

  static double getTotalPrice() {
    double total = 0;
    for (var item in items) {
      total += (item.product.price * item.quantity).toDouble();
    }
    return total;
  }

  static int getItemCount() {
    return items.length;
  }
}