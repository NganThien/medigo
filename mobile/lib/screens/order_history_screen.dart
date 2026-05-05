import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../configs.dart';
import 'order_detail_screen.dart';

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
  List<dynamic> _orders = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrderHistory();
  }

  Future<void> _fetchOrderHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user_data');

      if (userString == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không tìm thấy thông tin người dùng. Vui lòng đăng nhập lại.';
        });
        return;
      }

      final userData = jsonDecode(userString);
      final userId = userData['id'];

      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Thiếu user_id. Vui lòng đăng nhập lại.';
        });
        return;
      }

      final url = Uri.parse('${Configs.baseUrl}/orders/history');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['orders'] as List<dynamic>? ?? [];
        setState(() {
          _orders = list;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi server: ${response.statusCode}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi kết nối: $e';
      });
    }
  }

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

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('HH:mm dd/MM/yyyy').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Hoàn thành';
      case 'pending':
        return 'Chờ xử lý';
      case 'shipping':
        return 'Đang giao';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  static const List<String> _tabStatuses = [
    'all',
    'pending',
    'shipping',
    'completed',
    'cancelled',
    'cancelled_only',
  ];

  int _initialTabIndex() {
    final s = widget.initialStatus;
    if (s == null) return 0;
    if (s == 'cancelled' || s == 'canceled') return 5;
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
        onRefresh: _fetchOrderHistory,
        child: _buildOrderList(_orders),
      );
    }

    if (status == 'cancelled_only') {
      final cancelledOrders = _orders.where((e) {
        final s = (e as Map<String, dynamic>)['status'] as String?;
        return s == 'cancelled' || s == 'canceled';
      }).toList();
      return RefreshIndicator(
        onRefresh: _fetchOrderHistory,
        child: _buildOrderList(cancelledOrders),
      );
    }

    final filtered = _orders.where((e) {
      final s = (e as Map<String, dynamic>)['status'] as String?;
      return s == status;
    }).toList();
    return RefreshIndicator(
      onRefresh: _fetchOrderHistory,
      child: _buildOrderList(filtered),
    );
  }

  Widget _buildOrderList(List<dynamic> orders) {
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
        final order = orders[index] as Map<String, dynamic>;
        final id = order['id'];
        final totalAmount = (order['total_amount'] as num?) ?? 0;
        final status = (order['status'] as String?) ?? 'unknown';
        final createdAt = order['created_at'] as String?;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: InkWell(
            onTap: () async {
              final needReload = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => OrderDetailScreen(orderId: id as int),
                ),
              );
              if (needReload == true && mounted) _fetchOrderHistory();
            },
            borderRadius: BorderRadius.circular(12),
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
                            horizontal: 10, vertical: 4),
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
          ),
        );
      },
    );
  }

}

