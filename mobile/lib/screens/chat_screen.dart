import 'package:flutter/material.dart';
import '../models/chat_data.dart';

// ==========================================
// HÀM GỌI POPUP TƯ VẤN (Gọi từ nút trái tim)
// ==========================================
void showConsultationBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tư vấn với Dược sĩ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Ảnh minh họa (Bạn có thể thêm ảnh asset của bạn vào đây)
            Icon(Icons.support_agent, size: 100, color: Colors.blue[300]),
            const SizedBox(height: 16),
            const Text(
              'Vui lòng chọn hình thức tư vấn\n(Hoàn toàn miễn phí)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            
            // Nút Nhắn tin
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8F0FE), // Màu xanh nhạt
                  foregroundColor: Colors.blue[800],
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Nhắn tin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(context); // Tắt popup
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatScreen()), // Mở màn chat
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            
            // Nút Gọi tổng đài
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[800],
                  side: BorderSide(color: Colors.blue[200]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                icon: const Icon(Icons.phone_in_talk),
                label: const Text('Gọi tổng đài (1800 6928)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () {
                  // Chỗ này sau dùng url_launcher gọi điện
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đang gọi tổng đài...')),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}

// ==========================================
// MÀN HÌNH CHAT VỚI DƯỢC SĨ
// ==========================================
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatData _chatData = ChatData(); // Lấy kho dữ liệu chung

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _chatData.messages.add(
        ChatMessage(text: _controller.text, isUser: true, time: DateTime.now()),
      );
    });
    
    _controller.clear();
    _scrollToBottom();

    // Giả lập Dược sĩ trả lời sau 1.5 giây
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _chatData.messages.add(
            ChatMessage(
              text: "Dược sĩ MediGo đã nhận được câu hỏi. Xin đợi một lát để chúng tôi kiểm tra thông tin thuốc nhé!", 
              isUser: false, 
              time: DateTime.now()
            ),
          );
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dược sĩ MediGo'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _chatData.messages.length,
              itemBuilder: (context, index) {
                final msg = _chatData.messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Colors.blue[600] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(20),
                        bottomLeft: msg.isUser ? const Radius.circular(20) : const Radius.circular(0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.text,
                          style: TextStyle(
                            color: msg.isUser ? Colors.white : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _chatData.getFormattedTime(msg.time),
                          style: TextStyle(
                            color: msg.isUser ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) {
                      _sendMessage(); 
                    },
                    decoration: InputDecoration(
                      hintText: 'Bạn cần hỗ trợ gì?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}