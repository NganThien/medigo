import 'product.dart';

// 1. Định nghĩa "Một món hàng trong giỏ"
class CartItem {
  final Product product; // Thông tin thuốc
  int quantity; // Số lượng mua

  CartItem({required this.product, this.quantity = 1});
}

// 2. Định nghĩa "Cái Giỏ Hàng" (Quản lý toàn bộ)
class Cart {
  // Biến static: Để giỏ hàng này là DUY NHẤT trong toàn App (Singleton đơn giản)
  // Dù bạn ở màn hình nào thì cũng truy cập vào đúng cái giỏ này.
  static List<CartItem> items = [];

  // Hàm: Thêm vào giỏ
  static void addToCart(Product product, int quantity) {
    // Kiểm tra xem thuốc này đã có trong giỏ chưa?
    final index = items.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      // Nếu có rồi -> Chỉ cần cộng thêm số lượng
      items[index].quantity += quantity;
    } else {
      // Nếu chưa có -> Thêm món mới vào
      items.add(CartItem(product: product, quantity: quantity));
    }
  }

  // Hàm: Xóa khỏi giỏ
  static void removeFromCart(int index) {
    items.removeAt(index);
  }

  // Hàm: Tính tổng tiền
  static double getTotalPrice() {
    double total = 0;
    for (var item in items) {
      total += (item.product.price * item.quantity);
    }
    return total;
  }

  // Hàm: Đếm tổng số món hàng (để hiện số nhỏ nhỏ ở icon giỏ hàng nếu muốn)
  static int getItemCount() {
    return items.length;
  }

  // Hàm: Xóa toàn bộ giỏ hàng
  static void clearCart() {
    items.clear();
  }
}
