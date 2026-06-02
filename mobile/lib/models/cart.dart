import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'product.dart';
import '../configs.dart'; // Đảm bảo đường dẫn này trỏ đúng file có Configs.baseUrl

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class Cart {
  static List<CartItem> items = [];
  static int? _userId;

  // 1. GỌI HÀM NÀY ĐỂ KÉO GIỎ HÀNG TỪ SERVER VỀ KHI MỞ APP
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
      final response = await http.get(
        Uri.parse('${Configs.baseUrl}/cart/$_userId'),
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

  // 2. THÊM VÀO GIỎ (Cập nhật RAM tức thì + Ghi ngầm vào DB)
  static Future<void> addToCart(Product product, int quantity) async {
    final index = items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      items[index].quantity += quantity;
    } else {
      items.add(CartItem(product: product, quantity: quantity));
    }

    // Bắn lên Server
    if (_userId != null) {
      try {
        await http.post(
          Uri.parse('${Configs.baseUrl}/cart/add'),
          headers: {'Content-Type': 'application/json'},
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

  // 3. XÓA KHỎI GIỎ
  static Future<void> removeFromCart(int index) async {
    if (index < 0 || index >= items.length) return;

    final productId = items[index].product.id;
    items.removeAt(index); // Xóa ở RAM

    if (_userId != null) {
      try {
        await http.delete(
          Uri.parse('${Configs.baseUrl}/cart/remove/$_userId/$productId'),
        );
      } catch (e) {
        print('Lỗi xóa DB: $e');
      }
    }
  }

  // 4. LÀM SẠCH GIỎ (Dùng khi thanh toán xong)
  static Future<void> clearCart() async {
    items.clear();
    if (_userId != null) {
      try {
        await http.delete(Uri.parse('${Configs.baseUrl}/cart/clear/$_userId'));
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
