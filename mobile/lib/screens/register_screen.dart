import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../configs.dart'; // Import file cấu hình IP

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    final phone = _phoneController.text.trim();
    final password = _passController.text.trim();
    final name = _nameController.text.trim();

    // 1. Kiểm tra không được để trống
    if (phone.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập Họ tên, SĐT và Mật khẩu!')),
      );
      return;
    }

    // 2. KIỂM TRA ĐỊNH DẠNG SĐT VIỆT NAM (REGEX)
    // Quy tắc: Bắt đầu bằng 0 hoặc +84, tiếp theo là 3,5,7,8,9 và có đúng 8 số đằng sau.
    final phoneRegex = RegExp(r'^(0|\+84)[3|5|7|8|9][0-9]{8}$');
    if (!phoneRegex.hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'SĐT không hợp lệ! Vui lòng nhập đúng 10 số (VD: 098..., 032...)',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return; // Khóa chặn, không cho chạy tiếp xuống dưới
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('${Configs.baseUrl}/register');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': password,
          'full_name': name,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201) {
        // Đăng ký thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
            backgroundColor: Colors.green,
          ),
        );
        // Quay lại màn hình đăng nhập
        Navigator.pop(context);
      } else {
        // Lỗi (SĐT đã tồn tại...)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Đăng ký thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký tài khoản")),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Ô nhập Họ tên
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Họ và tên",
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ô nhập SĐT
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Số điện thoại",
                prefixIcon: const Icon(Icons.phone_android),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ô nhập Mật khẩu
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Mật khẩu",
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Nút Đăng ký
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009688),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "ĐĂNG KÝ",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
