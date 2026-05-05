import 'package:flutter/material.dart';
import 'home_tab.dart'; // Chúng ta sẽ tạo file này ở Bước 3
import 'profile_screen.dart';
import 'cart_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  // Danh sách các màn hình tương ứng với 5 nút
  final List<Widget> _screens = [
    const HomeTab(), // Trang chủ (Sẽ làm ở bước 3)
    const Center(child: Text('Màn hình Điểm thưởng')), // Placeholder
    const Center(child: Text('Màn hình Tư vấn')), // Placeholder
    const CartScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _screens.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed, // Quan trọng: Để hiện đủ 5 nút
        selectedItemColor: const Color(0xFF0056B3), // Màu xanh khi chọn
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user),
            label: 'Điểm thưởng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: 'Tư vấn',
            backgroundColor: Colors.blue,
          ), // Nút to ở giữa
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Giỏ hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
