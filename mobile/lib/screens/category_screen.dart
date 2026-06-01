import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'search_screen.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import '../models/product.dart';
import '../models/category.dart'; // Đã thêm Model Category
import '../services/api_service.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  int _selectedIndex = 0;
  late Future<List<Product>> _futureProducts;

  // 1. Chứa danh mục THẬT lấy từ Database
  List<Category> _serverCategories = [];
  bool _isLoadingCats = true;

  // 2. Bộ Icon và Màu sắc để trang trí (Sẽ xoay vòng gán vào danh mục thật)
  final List<Map<String, dynamic>> _decorations = [
    {'icon': Icons.medication, 'color': Colors.blue},
    {'icon': Icons.health_and_safety, 'color': Colors.green},
    {'icon': Icons.spa, 'color': Colors.purple},
    {'icon': Icons.child_care, 'color': Colors.pink},
    {'icon': Icons.face_retouching_natural, 'color': Colors.orange},
    {'icon': Icons.monitor_heart, 'color': Colors.redAccent},
    {'icon': Icons.local_mall, 'color': Colors.teal},
    {'icon': Icons.favorite_border, 'color': Colors.deepOrange},
  ];

  @override
  void initState() {
    super.initState();
    _loadRealCategories(); // Gọi API kéo danh mục ngay khi mở trang
  }

  // HÀM LẤY DANH MỤC TỪ SERVER
  Future<void> _loadRealCategories() async {
    try {
      final cats = await ApiService.fetchCategories();
      setState(() {
        _serverCategories = cats;
        _isLoadingCats = false;
      });

      // Nếu có danh mục, tự động load thuốc của danh mục đầu tiên
      if (cats.isNotEmpty) {
        _loadProductsForCategory(0);
      }
    } catch (e) {
      setState(() => _isLoadingCats = false);
    }
  }

  // HÀM LẤY SẢN PHẨM THEO ID THẬT
  void _loadProductsForCategory(int index) {
    setState(() {
      _selectedIndex = index;
      // Truyền đúng ID thật của danh mục vào API
      // (Lưu ý: Nếu Model Category của bạn không dùng biến 'id', hãy sửa lại cho khớp)
      int realId = int.tryParse(_serverCategories[index].id.toString()) ?? 0;
      _futureProducts = ApiService.fetchProducts(categoryId: realId);
    });
  }

  String formatCurrency(int price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            );
          },
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: const [
                Icon(Icons.search, color: Colors.grey, size: 20),
                SizedBox(width: 8),
                Text(
                  "Tìm tên thuốc, bệnh lý...",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.black54,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- CỘT TRÁI: MENU DANH MỤC TỪ SERVER ---
          Container(
            width: 95,
            color: Colors.grey[50],
            child: _isLoadingCats
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  )
                : ListView.builder(
                    itemCount: _serverCategories.length,
                    itemBuilder: (context, index) {
                      final category = _serverCategories[index];
                      final isSelected = _selectedIndex == index;

                      // Xoay vòng lấy màu và icon trang trí
                      final deco = _decorations[index % _decorations.length];
                      final catColor = deco['color'] as Color;
                      final catIcon = deco['icon'] as IconData;

                      return GestureDetector(
                        onTap: () => _loadProductsForCategory(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isSelected
                                    ? catColor
                                    : Colors.transparent,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? catColor.withOpacity(0.15)
                                      : Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  catIcon,
                                  color: isSelected
                                      ? catColor
                                      : Colors.grey[500],
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category.name, // HIỂN THỊ TÊN THẬT TỪ DATABASE
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? Colors.black87
                                      : Colors.grey[600],
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // --- CỘT PHẢI: SẢN PHẨM ---
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: _isLoadingCats
                  ? const SizedBox() // Chờ load danh mục xong mới load thuốc
                  : FutureBuilder<List<Product>>(
                      future: _futureProducts,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.teal,
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 60,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Đang cập nhật\nsản phẩm cho mục này.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.65,
                              ),
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(snapshot.data![index]);
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7F9FC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Hero(
                  tag: 'cat_img_${product.id}',
                  child: Image.asset(
                    product.imageUrl.isNotEmpty
                        ? product.imageUrl
                        : "assets/images/placeholder.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatCurrency(product.price),
                    style: const TextStyle(
                      color: Color(0xFF009688),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
