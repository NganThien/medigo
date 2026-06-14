import 'package:flutter/material.dart';
import 'package:medigo/models/chat_data.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ChatData().loadMessages();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trạm thuốc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0056B3),
          primary: const Color(0xFF0056B3),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5FA),
      ),
      // Chỉ giữ lại MỘT màn hình home chính
      home: const LoginScreen(),
    );
  }
}
