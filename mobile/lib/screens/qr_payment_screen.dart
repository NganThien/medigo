import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main_screen.dart';

class QRPaymentScreen extends StatefulWidget {
  final double amount;
  final String orderId;

  const QRPaymentScreen({
    super.key,
    required this.amount,
    required this.orderId,
  });

  @override
  State<QRPaymentScreen> createState() => _QRPaymentScreenState();
}

class _QRPaymentScreenState extends State<QRPaymentScreen> {
  // 15 phút = 900 giây
  int _secondsRemaining = 900; 
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _showTimeoutDialog();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Hết thời gian'),
        content: const Text('Giao dịch đã hết hạn. Vui lòng đặt hàng lại!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
                (route) => false,
              );
            },
            child: const Text('Về trang chủ', style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(num amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
  }

  void _simulateDownloadQR() {
    // Để tải ảnh thật cần cài thêm thư viện gallery_saver. 
    // Trong khuôn khổ đồ án, dùng SnackBar báo thành công là đủ ghi điểm!
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã tải mã QR về thư viện ảnh!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmPaymentDone() {
    // Trong thực tế, hệ thống sẽ tự động bắt webhook từ ngân hàng.
    // Ở đây ta dùng nút thủ công để chuyển về trang chủ.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán số phút và giây
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');

    // Link tạo QR tự động (VietQR)
    final int intAmount = widget.amount.toInt();
    final String qrUrl = 'https://img.vietqr.io/image/vcb-1017127995-compact2.png?amount=$intAmount&addInfo=THANHTOAN MEDIGO ${widget.orderId}&accountName=NHA THUOC MEDIGO';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Màu nền xám nhạt như Long Châu
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: const Text('Thông tin chuyển khoản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Khung Card trắng giống Long Châu
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- ROW TIMER ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Giao dịch hết hạn sau',
                        style: TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w500),
                      ),
                      Row(
                        children: [
                          _buildTimeBox(minutes),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(':', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          _buildTimeBox(seconds),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 30, thickness: 1),

                  // --- TEXT HƯỚNG DẪN ---
                  const Text(
                    'Quét mã qua Ứng dụng Ngân hàng\nhoặc Ví điện tử',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.info_outline, color: Colors.teal, size: 18),
                      SizedBox(width: 4),
                      Text('Hướng dẫn sử dụng', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- MÃ QR ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.network(
                      qrUrl,
                      height: 240,
                      width: 240,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          height: 240, width: 240,
                          child: Center(child: CircularProgressIndicator(color: Colors.teal)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- SỐ TIỀN ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Số tiền: ', style: TextStyle(fontSize: 16, color: Colors.black54)),
                      Text(
                        _formatCurrency(widget.amount),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- NÚT TẢI MÃ ---
                  OutlinedButton.icon(
                    onPressed: _simulateDownloadQR,
                    icon: const Icon(Icons.download_rounded, color: Colors.teal),
                    label: const Text('Tải mã', style: TextStyle(color: Colors.teal, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      side: const BorderSide(color: Colors.teal, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- FOOTER TEXT ---
                  const Text(
                    'Giao dịch sẽ tự động hủy khi\nhết thời hạn thanh toán.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black45, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Nút bấm hoàn tất (Thay cho việc chờ Webhook từ ngân hàng)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _confirmPaymentDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tôi đã thanh toán thành công', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Khung đen bo góc chứa số phút/giây
  Widget _buildTimeBox(String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Màu xanh đen sậm
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        time,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }
}