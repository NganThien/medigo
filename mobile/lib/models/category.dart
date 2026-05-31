import 'package:flutter/material.dart';

class Category {
  final int id;
  final String name;
  final IconData icon;

  Category({required this.id, required this.name, required this.icon});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      icon: _getIconForCategory(json['name'] ?? ''),
    );
  }

  static IconData _getIconForCategory(String categoryName) {
    switch (categoryName) {
      case 'Tất cả':
        return Icons.apps;
      case 'Bồi Bổ & Đề Kháng':
        return Icons.health_and_safety;
      case 'Chăm Sóc Cá Nhân':
        return Icons.face_retouching_natural;
      case 'Cơ - Xương - Khớp':
        return Icons.accessibility_new;
      case 'Dạ Dày & Tiêu Hóa':
        return Icons.set_meal;
      case 'Hỗ Trợ Làm Đẹp':
        return Icons.spa;
      case 'Mẹ & Bé':
        return Icons.pregnant_woman;
      case 'Thiết Bị Y Tế':
        return Icons.medical_services;
      case 'Tủ Thuốc Gia Đình':
        return Icons.medication;
      default:
        return Icons.category;
    }
  }
}
