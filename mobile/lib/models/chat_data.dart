import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // 🟢 Import thư viện lưu trữ

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({required this.text, required this.isUser, required this.time});

  // 🟢 Chuyển đối tượng thành Map để mã hóa sang JSON String
  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'time': time.toIso8601String(),
      };

  // 🟢 Dịch từ JSON String ngược lại thành đối tượng ChatMessage
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'] ?? '',
        isUser: json['isUser'] ?? false,
        time: DateTime.parse(json['time'] ?? DateTime.now().toIso8601String()),
      );
}

class ChatData {
  static final ChatData _instance = ChatData._internal();
  factory ChatData() => _instance;
  ChatData._internal();

  List<ChatMessage> messages = [];

  // 🟢 HÀM TẢI TIN NHẮN CŨ (Gọi khi vừa bật ứng dụng)
  Future<void> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedList = prefs.getStringList('chat_history');

    if (savedList != null && savedList.isNotEmpty) {
      messages = savedList
          .map((item) => ChatMessage.fromJson(jsonDecode(item)))
          .toList();
    } else {
      // Câu chào mặc định nếu lần đầu tiên cài app chưa chat gì
      messages = [
        ChatMessage(
          text: "Chào bạn! Chúc bạn một ngày tốt lành. Dược sĩ MediGo có thể giúp gì cho bạn?",
          isUser: false,
          time: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ];
    }
  }

  // 🟢 HÀM GHI TIN NHẮN XUỐNG THIẾT BỊ (Gọi mỗi khi phát sinh tin nhắn mới)
  Future<void> saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> stringList =
        messages.map((msg) => jsonEncode(msg.toJson())).toList();
    await prefs.setStringList('chat_history', stringList);
  }

  String getFormattedTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}