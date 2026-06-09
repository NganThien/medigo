import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  // Bắt buộc phải có chữ OrderDetailScreen khớp 100% để file History không bị lỗi đỏ
  const OrderDetailScreen({super.key, required this.order});

  String _formatCurrency(num? amount) {
    if (amount == null) return '0 VND';
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final reversedIndex = str.length - i - 1;
      buffer.write(str[i]);
      if (reversedIndex % 3 == 0 && i != str.length - 1) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()} VND';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed': return 'Đã giao';
      case 'pending': return 'Đang xử lý';
      case 'shipping': return 'Đang giao';
      case 'cancelled': return 'Đã hủy';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = order['items'] as List? ?? [];
    final totalAmount = (order['total_amount'] as num?) ?? 0;
    final status = (order['status'] as String?) ?? 'unknown';
    final id = order['id']?.toString() ?? '—';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text('Chi tiết đơn hàng #$id'),
        backgroundColor: const Color(0xFF009688),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // KHỐI 1: THÔNG TIN CHUNG
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Trạng thái', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    Text(
                      _statusLabel(status),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng thanh toán', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    Text(
                      _formatCurrency(totalAmount),
                      style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          const Text('SẢN PHẨM ĐÃ ĐẶT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),

          // KHỐI 2: DANH SÁCH THUỐC
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ảnh Thuốc
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                              ? Image.network(item['image_url'], fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.medication, color: Colors.grey))
                              : const Icon(Icons.medication, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Tên + SL + Giá
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? 'Tên sản phẩm',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text('Số lượng: ${item['quantity']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              _formatCurrency((item['price_at_purchase'] as num?) ?? (item['price'] as num?) ?? 0), 
                              // Dòng này an toàn vì nó thử cả 2 tên key phổ biến nhất
                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}