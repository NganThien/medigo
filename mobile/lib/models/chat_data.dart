import 'package:flutter/material.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({required this.text, required this.isUser, required this.time});
}

// Kho lưu trữ tạm thời (Singleton) để giữ lịch sử chat khi chưa có DB
class ChatData {
  static final ChatData _instance = ChatData._internal();
  factory ChatData() => _instance;
  ChatData._internal();

  // Khởi tạo sẵn một câu chào mừng của hệ thống
  List<ChatMessage> messages = [
    ChatMessage(
      text: "Chào bạn! Chúc bạn một ngày tốt lành. Dược sĩ MediGo có thể giúp gì cho bạn?", 
      isUser: false, 
      time: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  // Hàm định dạng thời gian (VD: 14:30)
  String getFormattedTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}