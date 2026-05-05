import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/cart.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1; // Mặc định mua 1 cái

  // Hàm định dạng tiền (VND)
  String formatCurrency(double price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  void _addCurrentProductToCart() {
    Cart.addToCart(widget.product, _quantity);
  }

  void _buyNow() {
    final checkoutItems = [
      CartItem(product: widget.product, quantity: _quantity),
    ];
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    Navigator.pop(context);
    rootNavigator.push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(items: checkoutItems),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 1. APP BAR TRONG SUỐT (Để ảnh tràn lên trên cùng)
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 2. ẢNH SẢN PHẨM LỚN
          Expanded(
            flex: 4, // Chiếm 40% màn hình
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5), // Nền xám nhạt
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Hero(
                tag:
                    'product_img_${widget.product.id}', // Hiệu ứng bay từ màn hình trước
                child: Image.network(
                  widget.product.imageUrl.isNotEmpty
                      ? widget.product.imageUrl
                      : "https://cdn-icons-png.flaticon.com/512/883/883407.png",
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // 3. THÔNG TIN CHI TIẾT
          Expanded(
            flex: 6, // Chiếm 60% màn hình
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên thuốc
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Giá tiền
                  Text(
                    formatCurrency(widget.product.price),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF009688),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mô tả (Tiêu đề)
                  const Text(
                    "Mô tả sản phẩm",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Nội dung mô tả (Cuộn được nếu dài)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        widget.product.description.isNotEmpty
                            ? widget.product.description
                            : "Chưa có mô tả chi tiết cho sản phẩm này.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),

                  // 4. THANH CHỌN SỐ LƯỢNG + NÚT MUA
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Nút trừ
                      _buildQuantityButton(Icons.remove, () {
                        if (_quantity > 1) setState(() => _quantity--);
                      }),
                      const SizedBox(width: 15),
                      // Số lượng
                      Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Nút cộng
                      _buildQuantityButton(Icons.add, () {
                        setState(() => _quantity++);
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.teal),
                            foregroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            _addCurrentProductToCart();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã thêm vào giỏ hàng'),
                              ),
                            );
                          },
                          child: const Text('Thêm vào giỏ'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            _buyNow();
                          },
                          child: const Text('Mua ngay'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget nút cộng trừ nhỏ nhỏ
  Widget _buildQuantityButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
