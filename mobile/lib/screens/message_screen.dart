import 'package:flutter/material.dart';
import 'cart_screen.dart';
import '../models/chat_data.dart'; // 🟢 Bổ sung import kho dữ liệu
import 'chat_screen.dart';         // 🟢 Bổ sung import màn hình chat

// Đổi thành StatefulWidget để màn hình tự cập nhật khi có tin nhắn mới
class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final ChatData _chatData = ChatData(); // Khởi tạo kho dữ liệu chat

  @override
  Widget build(BuildContext context) {
    // Lấy tin nhắn cuối cùng để hiển thị preview
    final lastMessage = _chatData.messages.isNotEmpty 
        ? _chatData.messages.last 
        : null;

    return DefaultTabController(
      length: 2, // 2 Tabs
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Tin nhắn',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          // NÚT GIỎ HÀNG Ở GÓC PHẢI
          actions: [
            IconButton(
              icon: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.black87,
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
          bottom: const TabBar(
            labelColor: Colors.pink, // Màu chữ khi chọn (Giống ảnh)
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.pink,
            tabs: [
              Tab(text: 'Nhà thuốc'),
              Tab(text: 'Bác sĩ'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 🟢 ĐÃ SỬA: Nội dung Tab 1 (Nhà thuốc) hiển thị lịch sử chat
            lastMessage == null
                ? const Center(child: Text('Chưa có tin nhắn với nhà thuốc'))
                : ListView(
                    children: [
                      InkWell(
                        onTap: () {
                          // Mở lại màn hình chat và reload giao diện khi quay lại
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ChatScreen()),
                          ).then((_) => setState(() {})); 
                        },
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(top: 2), // Tạo đường line mỏng
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.blue[100],
                                child: const Icon(Icons.support_agent, color: Colors.blue, size: 30),
                              ),
                              const SizedBox(width: 16),
                              // Nội dung
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Dược sĩ MediGo',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          _chatData.getFormattedTime(lastMessage.time),
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      lastMessage.isUser ? "Bạn: ${lastMessage.text}" : lastMessage.text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: lastMessage.isUser ? Colors.grey[600] : Colors.black87,
                                        fontWeight: lastMessage.isUser ? FontWeight.normal : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

            // 🟢 GIỮ NGUYÊN: Nội dung Tab 2 (Bác sĩ) của bạn
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: 100,
                  color: Colors.blue[300],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Đội ngũ bác sĩ MediGo\nluôn hỗ trợ bạn bất kể ngày đêm',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'DANH SÁCH BÁC SĨ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}