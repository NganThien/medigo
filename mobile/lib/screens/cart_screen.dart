import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cart.dart'; // Import cái giỏ hàng
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Chọn mua hay không: true = mua, false = không mua
  List<bool> _selectedItems = [];

  void _syncSelectedList() {
    while (_selectedItems.length < Cart.items.length) {
      _selectedItems.add(true);
    }
    if (_selectedItems.length > Cart.items.length) {
      _selectedItems = _selectedItems.sublist(0, Cart.items.length);
    }
  }

  double _getSelectedTotal() {
    double total = 0;
    for (int i = 0; i < Cart.items.length; i++) {
      if (i < _selectedItems.length && _selectedItems[i]) {
        total += Cart.items[i].product.price * Cart.items[i].quantity;
      }
    }
    return total;
  }

  List<CartItem> _getSelectedItems() {
    final list = <CartItem>[];
    for (int i = 0; i < Cart.items.length; i++) {
      if (i < _selectedItems.length && _selectedItems[i]) {
        list.add(Cart.items[i]);
      }
    }
    return list;
  }

  // Hàm định dạng tiền
  String formatCurrency(double price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  // Hàm cập nhật lại giao diện khi xóa/sửa
  void _updateCart() {
    setState(() {});
  }

  void _goToCheckout() {
    if (Cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Giỏ hàng đang trống!")),
      );
      return;
    }

    _syncSelectedList();
    final selected = _getSelectedItems();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng tích chọn ít nhất một món để đặt hàng!")),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(items: selected),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Đồng bộ danh sách chọn trước khi tính tổng (tránh tổng = 0 khi mới vào màn hình)
    _syncSelectedList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: const Text("Giỏ hàng của bạn"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Cart.items.isEmpty
          ? const Center(child: Text("Giỏ hàng đang trống!"))
          : Column(
              children: [
                // 1. DANH SÁCH HÀNG
                Expanded(
                  child: ListView.builder(
                    itemCount: Cart.items.length,
                    padding: const EdgeInsets.all(15),
                    itemBuilder: (context, index) {
                      _syncSelectedList();
                      final item = Cart.items[index];
                      final isSelected = index < _selectedItems.length && _selectedItems[index];
                      return Opacity(
                        opacity: isSelected ? 1.0 : 0.6,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                // Checkbox: tích = mua, bỏ tích = không mua
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      _syncSelectedList();
                                      if (index < _selectedItems.length) {
                                        _selectedItems[index] = value ?? false;
                                      }
                                    });
                                  },
                                  activeColor: const Color(0xFF009688),
                                ),
                                // Ảnh nhỏ
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Image.network(
                                  item.product.imageUrl.isNotEmpty
                                      ? item.product.imageUrl
                                      : "https://cdn-icons-png.flaticon.com/512/883/883407.png",
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 15),
                              // Thông tin
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      formatCurrency(item.product.price),
                                      style: const TextStyle(
                                        color: Color(0xFF009688),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "Số lượng: ${item.quantity}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Nút Xóa
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  Cart.removeFromCart(index);
                                  if (index < _selectedItems.length) {
                                    _selectedItems.removeAt(index);
                                  }
                                  _updateCart();
                                },
                              ),
                            ],
                          ),
                        ),
                        ),
                      );
                    },
                  ),
                ),

                // 2. PHẦN TỔNG TIỀN VÀ THANH TOÁN
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Tổng cộng:",
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            formatCurrency(_getSelectedTotal()),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _goToCheckout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009688),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "TIẾN HÀNH ĐẶT HÀNG",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
