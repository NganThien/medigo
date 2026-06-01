import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/order_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  final String? initialStatus;

  const OrderHistoryScreen({super.key, this.initialStatus});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Gọi API lấy dữ liệu mới nhất từ MySQL thông qua OrderService
    await OrderService.loadOrders();
    final list = OrderService.getAllOrders();

    setState(() {
      _orders = list;
      _isLoading = false;
    });
  }

  // SỬA LỖI 3: Đồng bộ trạng thái Tiếng Anh của Flask -> Màu sắc
  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'shipping':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // SỬA LỖI 3: Đồng bộ trạng thái Tiếng Anh của Flask -> Chữ Tiếng Việt cho User xem
  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Đã giao';
      case 'pending':
        return 'Đang xử lý';
      case 'shipping':
        return 'Đang giao';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '—';
    try {
      final dt = value is DateTime ? value : DateTime.parse(value.toString());
      return DateFormat('HH:mm dd/MM/yyyy').format(dt);
    } catch (_) {
      return value.toString();
    }
  }

  // SỬA LỖI 3: Dùng đúng từ khóa của Backend để làm bộ lọc Tab
  static const List<String> _tabStatuses = [
    'all',
    'pending', // Thay vì 'Đang xử lý'
    'shipping', // Thay vì 'Đang giao'
    'completed', // Thay vì 'Đã giao'
    'returned', // Đổi/Trả
    'cancelled', // Thay vì 'cancelled_only'
  ];

  int _initialTabIndex() {
    final s = widget.initialStatus;
    if (s == null) return 0;
    if (s == 'cancelled' || s == 'canceled' || s == 'Cancelled') return 5;
    if (s == 'pending') return 1;
    if (s == 'shipping') return 2;
    if (s == 'completed') return 3;
    final i = _tabStatuses.indexOf(s);
    return i >= 0 ? i : 0;
  }

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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      initialIndex: _initialTabIndex(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lịch sử đơn hàng'),
          backgroundColor: const Color(0xFF009688),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Tất cả'),
              Tab(text: 'Đang xử lý'),
              Tab(text: 'Đang giao'),
              Tab(text: 'Đã giao'),
              Tab(text: 'Đổi/Trả'),
              Tab(text: 'Đã hủy'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorWidget()
            : TabBarView(
                children: _tabStatuses
                    .map((status) => _buildOrderListForTab(status))
                    .toList(),
              ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.error_outline, color: Colors.red[300], size: 60),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderListForTab(String status) {
    if (status == 'all') {
      return RefreshIndicator(
        onRefresh: _loadOrders,
        child: _buildOrderList(_orders),
      );
    }

    // Lọc theo đúng trạng thái tiếng Anh (pending, completed...)
    final filtered = _orders
        .where((e) => (e['status'] as String?) == status)
        .toList();
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: _buildOrderList(filtered),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.receipt_long_outlined, color: Colors.grey, size: 60),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Chưa có đơn nào trong mục này.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final id = order['id']?.toString() ?? '—';

        // SỬA LỖI 1 & 2: Dùng đúng key JSON từ Flask
        final totalAmount =
            (order['total_amount'] as num?) ?? 0; // Chỗ này hết 0 VNĐ rồi nhé!
        final status = (order['status'] as String?) ?? 'unknown';
        final createdAt = order['created_at']; // Hiển thị ngày giờ chuẩn

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mã đơn #$id',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tổng tiền: ${_formatCurrency(totalAmount)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ngày tạo: ${_formatDate(createdAt)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
