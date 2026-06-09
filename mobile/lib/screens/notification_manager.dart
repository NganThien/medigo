import 'package:flutter/material.dart';

// 1. Cấu trúc của 1 dòng thông báo
class AppNotification {
  final String title;
  final String content;
  final String time;
  bool isUnread;
  final IconData icon;
  final Color color;

  AppNotification({
    required this.title,
    required this.content,
    required this.time,
    this.isUnread = true,
    required this.icon,
    required this.color,
  });
}

// 2. Bộ quản lý toàn cục
class NotificationManager {
  // Biến cờ hiệu: Bật/Tắt chấm đỏ ngoài Trang chủ
  static final ValueNotifier<bool> hasUnread = ValueNotifier(true);

  // Danh sách thông báo thực tế (Có sẵn 1 tin nhắn chào mừng)
  static List<AppNotification> notifications = [
    AppNotification(
      title: 'Chào mừng đến với MediGo',
      content:
          'Cảm ơn bạn đã đăng ký tài khoản. Chúc bạn có trải nghiệm chăm sóc sức khỏe tuyệt vời cùng chúng tôi.',
      time: 'Vừa xong',
      isUnread: true,
      icon: Icons.verified_user,
      color: const Color(0xFF009688),
    ),
  ];

  // 👉 GỌI HÀM NÀY MỖI KHI ĐẶT HÀNG THÀNH CÔNG
  static void addNew(String title, String content, IconData icon, Color color) {
    notifications.insert(
      0, // Luôn chèn thông báo mới nhất lên đầu danh sách
      AppNotification(
        title: title,
        content: content,
        time: 'Vừa xong',
        isUnread: true,
        icon: icon,
        color: color,
      ),
    );
    hasUnread.value = true; // Bật chấm đỏ lên
  }

  // 👉 GỌI HÀM NÀY KHI BẤM NÚT "ĐÃ ĐỌC"
  static void markAllAsRead() {
    for (var item in notifications) {
      item.isUnread = false;
    }
    hasUnread.value = false; // Tắt chấm đỏ ngoài màn hình chính đi
  }
}
