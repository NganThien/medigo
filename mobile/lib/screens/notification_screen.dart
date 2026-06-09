import 'package:flutter/material.dart';
import 'notification_manager.dart'; // Gọi bộ quản lý vào

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 👉 XỬ LÝ NÚT ĐÃ ĐỌC
              setState(() {
                NotificationManager.markAllAsRead();
              });
            },
            child: const Text(
              'Đã đọc',
              style: TextStyle(
                color: Color(0xFF009688),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      // Danh sách tự động cuộn
      body: NotificationManager.notifications.isEmpty
          ? const Center(child: Text('Chưa có thông báo nào'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: NotificationManager.notifications.length,
              itemBuilder: (context, index) {
                final item = NotificationManager.notifications[index];
                return _buildNotificationItem(item);
              },
            ),
    );
  }

  // Giao diện 1 ô thông báo
  Widget _buildNotificationItem(AppNotification item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.isUnread ? Colors.blue.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: item.isUnread
            ? Border.all(color: Colors.blue.withOpacity(0.15))
            : Border.all(color: Colors.transparent),
        boxShadow: [
          if (!item.isUnread)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: item.isUnread
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Chấm đỏ nhỏ trên từng ô thông báo chưa đọc
                    if (item.isUnread)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE91E63),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: item.isUnread ? Colors.black87 : Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
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
