import 'dart:async';
import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'profile_screen.dart';
import 'category_screen.dart';
import 'message_screen.dart';
import 'chat_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  bool _showHeart = true;
  Timer? _timer;

  final List<Widget> _screens = [
    const HomeTab(),
    const CategoryScreen(),
    const Center(child: Text('Màn hình Tư vấn')),
    const MessageScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _screens.length - 1);

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) setState(() => _showHeart = !_showHeart);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- WIDGET VẼ 4 NÚT ---
  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? const Color(0xFFE91E63)
        : const Color(0xFF757575);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque, // Bắt sự kiện chạm mượt mà
        child: Padding(
          // Đệm 8px từ đáy để thẳng hàng tuyệt đối với chữ "Tư vấn"
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: Container(
                  height: 2,
                  width: 16,
                  margin: const EdgeInsets.only(bottom: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Icon(isSelected ? activeIcon : icon, color: color, size: 24),
              const SizedBox(height: 1), // Ép icon và chữ ôm sát nhau
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: _screens[_currentIndex],

      // --- NÚT TRUNG TÂM (FAB) ---
      floatingActionButton: GestureDetector(
        onTap: () => showConsultationBottomSheet(context),
        child: Container(
          width: 52, // Nút bo nhỏ lại cho thanh thoát
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF4081), Color(0xFFE91E63)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE91E63).withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: _showHeart
                  ? Stack(
                      key: const ValueKey('heart'),
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 24,
                        ),
                        Positioned(
                          top: 4,
                          right: 0,
                          child: Icon(
                            Icons.add,
                            color: const Color(0xFFE91E63),
                            size: 10,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      '24/7',
                      key: ValueKey('247'),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- THANH BOTTOM BAR (CHIÊU BÀI CUỐI CÙNG) ---
      bottomNavigationBar: SafeArea(
        child: Container(
          height:
              52, // BẮT BUỘC ÉP LÙN: Xóa sổ 100% khoảng trắng thừa trên đỉnh icon!
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -3), // Hắt bóng nổi 3D lên
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // LỚP 1: Thanh màu trắng (Vẫn bị máy cưa cắt rãnh như bình thường)
              Positioned.fill(
                child: BottomAppBar(
                  shape: const CircularNotchedRectangle(),
                  notchMargin: 5.0,
                  color: Colors.white,
                  elevation: 0,
                  clipBehavior: Clip.antiAlias, // Cắt viền rãnh mượt mà
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: [
                      _buildNavItem(
                        0,
                        Icons.home_outlined,
                        Icons.home,
                        'Trang chủ',
                      ),
                      _buildNavItem(
                        1,
                        Icons.grid_view_outlined,
                        Icons.grid_view,
                        'Danh mục',
                      ),
                      const Expanded(
                        child: SizedBox(),
                      ), // KHOẢNG TRỐNG: Nhường chỗ cho nút lồi xuống
                      _buildNavItem(
                        3,
                        Icons.chat_bubble_outline,
                        Icons.chat_bubble,
                        'Tin nhắn',
                      ),
                      _buildNavItem(
                        4,
                        Icons.person_outline,
                        Icons.person,
                        'Tài khoản',
                      ),
                    ],
                  ),
                ),
              ),

              // LỚP 2: Chữ TƯ VẤN (Nổi lên trên cùng, vĩnh viễn không bị cắt)
              Positioned(
                bottom:
                    8.0, // Cùng chung 1 tỷ lệ 8.0 với 4 nút kia -> Đảm bảo thẳng hàng như kẻ thước
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => showConsultationBottomSheet(context),
                  child: Text(
                    'Tư vấn',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _currentIndex == 2
                          ? const Color(0xFFE91E63)
                          : const Color(0xFF757575),
                      fontSize: 10,
                      fontWeight: _currentIndex == 2
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
