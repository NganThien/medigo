import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/order_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  /// Tab mở mặc định: pending, shipping, completed, cancelled.
  final String? initialStatus;

  const OrderHistoryScreen({
    super.key,
    this.initialStatus,
  });

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

    final list = OrderService.getAllOrders();
    setState(() {
      _orders = list;
      _isLoading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Đã giao':
        return Colors.green;
      case 'Đang xử lý':
        return Colors.orange;
      case 'Đang giao':
        return Colors.blue;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
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

  String _statusLabel(String status) {
    switch (status) {
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  static const List<String> _tabStatuses = [
    'all',
    'Đang xử lý',
    'Đang giao',
    'Đã giao',
    'Đổi/Trả',
    'cancelled_only',
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
    // Định dạng đơn giản: thêm dấu chấm phân cách hàng nghìn
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

    if (status == 'cancelled_only') {
      final cancelledOrders =
          _orders.where((e) => (e['status'] as String?) == 'Cancelled').toList();
      return RefreshIndicator(
        onRefresh: _loadOrders,
        child: _buildOrderList(cancelledOrders),
      );
    }

    final filtered =
        _orders.where((e) => (e['status'] as String?) == status).toList();
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
        final totalAmount = (order['total'] as num?) ?? 0;
        final status = (order['status'] as String?) ?? 'unknown';
        final createdAt = order['date'];

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
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
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

