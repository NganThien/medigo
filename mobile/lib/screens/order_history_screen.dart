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

    // Ép app gọi API lấy dữ liệu mới nhất từ MySQL
    await OrderService.loadOrders();
    final list = OrderService.getAllOrders();

    setState(() {
      _orders = list;
      _isLoading = false;
    });
  }

  // --- BỘ DỊCH TRẠNG THÁI (Flask -> UI) ---
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
  // ----------------------------------------

  String _formatDate(dynamic value) {
    if (value == null) return '—';
    try {
      final dt = value is DateTime ? value : DateTime.parse(value.toString());
      return DateFormat('HH:mm dd/MM/yyyy').format(dt);
    } catch (_) {
      return value.toString();
    }
  }

  // Các tab bộ lọc dùng đúng từ khóa tiếng Anh của MySQL
  static const List<String> _tabStatuses = [
    'all',
    'pending',
    'shipping',
    'completed',
    'returned',
    'cancelled',
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
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
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
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final id = order['id']?.toString() ?? '—';
        final totalAmount = (order['total_amount'] as num?) ?? 0;
        final status = (order['status'] as String?) ?? 'unknown';
        final items =
            order['items'] as List? ?? []; // Lấy mảng sản phẩm từ Flask

        final firstItem = items.isNotEmpty ? items.first : null;

        // Tính tổng số lượng sản phẩm trong đơn
        int totalItemsCount = 0;
        for (var item in items) {
          totalItemsCount += (item['quantity'] as num?)?.toInt() ?? 0;
        }

        return Container(
          margin: const EdgeInsets.only(top: 8),
          color: Colors.white, // Nền trắng chuẩn Shopee
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Tên Shop & Trạng thái
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Yêu thích',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'MediGo Store',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _statusLabel(status).toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(status),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

              // 2. Chi tiết Sản phẩm đầu tiên
              if (firstItem != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ảnh sản phẩm
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child:
                              firstItem['image_url'] != null &&
                                  firstItem['image_url'].toString().isNotEmpty
                              ? Image.network(
                                  firstItem['image_url'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.medication,
                                    color: Colors.grey,
                                  ),
                                )
                              : const Icon(
                                  Icons.medication,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Tên và Giá
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstItem['name'] ?? 'Tên sản phẩm',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'x${firstItem['quantity']}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                _formatCurrency(
                                  (firstItem['price'] as num?) ?? 0,
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Nút xem thêm nếu có nhiều hơn 1 sản phẩm
              if (items.length > 1)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Xem thêm ${items.length - 1} sản phẩm...',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),

              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

              // 3. Tổng số tiền
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Tổng số tiền ($totalItemsCount sản phẩm): ',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _formatCurrency(totalAmount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors
                            .teal, // Đổi màu teal cho hợp app thuốc, nếu muốn đỏ Shopee thì dùng Colors.red
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

              // 4. Các nút hành động
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đơn hàng #$id',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            // TODO: Chuyển sang màn hình Chi tiết đơn hàng
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Xem chi tiết',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                          ),
                        ),

                        // ĐIỀU KIỆN Ở ĐÂY: Chỉ hiện nút "Mua lại" khi đơn đã Hoàn thành hoặc Đã hủy
                        if (status == 'completed' || status == 'cancelled') ...[
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Thêm logic nhét lại các món này vào Giỏ hàng
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Mua lại',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Khoảng xám ngăn cách giữa các đơn hàng (giống Shopee)
              Container(height: 8, color: Colors.grey[100]),
            ],
          ),
        );
      },
    );
  }
}
