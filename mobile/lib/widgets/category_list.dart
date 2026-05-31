import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/api_service.dart';

/// Widget danh sách danh mục cuộn ngang.
/// Tự gọi API GET /api/categories, hiển thị loading, và báo lại khi user chọn danh mục.
class CategoryList extends StatefulWidget {
  /// Danh mục đang được chọn (null = "Tất cả").
  final int? selectedCategoryId;

  /// Callback khi user bấm vào một danh mục. [categoryId] null = "Tất cả".
  final ValueChanged<int?> onCategorySelected;

  const CategoryList({
    super.key,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  State<CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  /// Gọi API GET /api/categories lấy danh mục thật từ Server.
  Future<void> _fetchCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await ApiService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categories = [];
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const double sectionHeight = 112;
    if (_isLoading) {
      return const SizedBox(
        height: sectionHeight,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return SizedBox(
        height: sectionHeight,
        child: Center(
          child: Text(
            'Không tải được danh mục',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      );
    }
    return SizedBox(
      height: sectionHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _buildItem(categoryId: null, name: 'Tất cả', icon: Icons.apps),
          ..._categories.map(
            (c) => _buildItem(categoryId: c.id, name: c.name, icon: c.icon),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required int? categoryId,
    required String name,
    required IconData icon,
  }) {
    final isSelected = widget.selectedCategoryId == categoryId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: () => widget.onCategorySelected(categoryId),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.teal : Colors.teal.shade50,
                border: Border.all(
                  color: isSelected ? Colors.teal : Colors.teal.shade200,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.teal,
                size: 30,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 70,
              height: 32,
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.teal : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
