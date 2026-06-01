import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cart.dart';
import '../services/address_service.dart';
import '../services/order_service.dart';
import 'address_list_screen.dart';
import 'main_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;

  const CheckoutScreen({super.key, required this.items});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _noteController = TextEditingController();
  Map<String, dynamic>? _currentAddress;

  static const List<String> _shippingOptions = [
    'Giao hàng hỏa tốc',
    'Giao đêm hỏa tốc (60-120 phút)',
    'Giao hàng tiêu chuẩn (1-3 ngày không kể thứ 7 chủ nhật)',
  ];
  static const List<String> _paymentOptions = [
    'Tiền mặt (COD)',
    'MoMo',
    'Zalo Pay',
    'Thẻ ATM',
    'Trạm Thuốc Pay',
  ];

  String _selectedShippingUnit =
      'Giao hàng tiêu chuẩn (1-3 ngày không kể thứ 7 chủ nhật)';
  String _selectedPaymentMethod = 'Thanh toán khi nhận hàng (COD)';

  final double _shippingFee = 15000;
  final double _shippingDiscount = 0;

  @override
  void initState() {
    super.initState();
    _currentAddress = AddressService.getDefaultAddress();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  int get _subTotal {
    int total = 0;
    for (final item in widget.items) {
      total += item.product.price * item.quantity;
    }
    return total;
  }

  double get _totalPayment =>
      _subTotal.toDouble() + _shippingFee - _shippingDiscount;

  String _formatCurrency(num amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
  }

  Future<void> placeOrder() async {
    // --- LẮP CHỐT BẢO VỆ Ở ĐÂY ---
    if (_currentAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm địa chỉ giao hàng trước khi đặt!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating, // Nổi lên cho đẹp
        ),
      );
      return; // Lập tức "quay xe", từ chối chạy các code bên dưới!
    }
    // -----------------------------

    // 1. ĐÓNG GÓI DỮ LIỆU ĐÚNG CHUẨN API FLASK YÊU CẦU
    final orderData = <String, dynamic>{
      'total_amount': _totalPayment,
      'address': _formatAddress(
        _currentAddress,
      ), // Ép thành chuỗi text thay vì Map
      'items': widget.items.map((e) {
        return {
          // Ép ID sản phẩm sang số nguyên (int) vì bảng OrderDetail trong MySQL yêu cầu số
          'product_id': int.tryParse(e.product.id.toString()) ?? 0,
          'quantity': e.quantity,
          'price': e.product.price,
        };
      }).toList(),
    };

    // 2. HIỆN VÒNG QUAY LOADING TRONG LÚC ĐỢI MẠNG
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.teal)),
    );

    // 3. BẮN DỮ LIỆU LÊN SERVER VÀ CHỜ KẾT QUẢ
    // Phải có chữ 'await' để đợi Server trả lời xong mới chạy tiếp
    final success = await OrderService.addOrder(orderData);

    // Tắt vòng quay loading
    if (mounted) Navigator.of(context).pop();

    // 4. XỬ LÝ KẾT QUẢ
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đặt hàng thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(milliseconds: 1500),
          ),
        );
      }

      Cart.clearCart(); // Xóa giỏ hàng

      // Chuyển về trang chủ
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đặt hàng thất bại. Vui lòng thử lại!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openAddressList() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const AddressListScreen()),
    );
    setState(() {
      _currentAddress = result ?? AddressService.getDefaultAddress();
    });
  }

  String _formatAddress(Map<String, dynamic>? item) {
    if (item == null) return 'Chưa có địa chỉ giao hàng';
    final parts = <String>[
      (item['street'] as String? ?? '').trim(),
      (item['ward'] as String? ?? '').trim(),
      (item['province'] as String? ?? '').trim(),
    ].where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? 'Chưa có địa chỉ giao hàng' : parts.join(', ');
  }

  Future<void> _showShippingOptionsSheet() async {
    String tempSelected = _selectedShippingUnit;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Chọn đơn vị vận chuyển',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._shippingOptions.map(
                      (option) => RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.teal,
                        value: option,
                        groupValue: tempSelected,
                        title: Text(option),
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() => tempSelected = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _selectedShippingUnit = tempSelected);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Xác nhận'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showPaymentOptionsSheet() async {
    String tempSelected = _selectedPaymentMethod;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Chọn phương thức thanh toán',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._paymentOptions.map(
                      (option) => RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.teal,
                        value: option,
                        groupValue: tempSelected,
                        title: Text(option),
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() => tempSelected = value);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _selectedPaymentMethod = tempSelected);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Áp dụng'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Thanh toán'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _buildAddressSection(),
          _buildProductSection(),
          _buildShippingSection(),
          _buildNoteSection(),
          _buildPaymentMethodSection(),
          _buildPaymentDetailSection(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAddressSection() {
    return InkWell(
      onTap: _openAddressList,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.location_on, color: Colors.teal),
                SizedBox(width: 6),
                Text(
                  'Thông tin người nhận',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_currentAddress?['fullName'] ?? 'Chưa cập nhật'} | '
                    '${_currentAddress?['phone'] ?? 'Chưa cập nhật'}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatAddress(_currentAddress),
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            _buildPostalStripe(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostalStripe() {
    return SizedBox(
      height: 4,
      child: Row(
        children: List.generate(28, (index) {
          final isTeal = index % 2 == 0;
          return Expanded(
            child: Container(color: isTeal ? Colors.teal : Colors.redAccent),
          );
        }),
      ),
    );
  }

  Widget _buildProductSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      child: Column(children: widget.items.map(_buildProductItem).toList()),
    );
  }

  Widget _buildProductItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              item.product.imageUrl.isNotEmpty
                  ? item.product.imageUrl
                  : 'assets/images/placeholder.png',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatCurrency(item.product.price),
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'x${item.quantity}',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingSection() {
    return InkWell(
      onTap: _showShippingOptionsSheet,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Đơn vị vận chuyển',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Text(
                _selectedShippingUnit,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _formatCurrency(_shippingFee),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            'Ghi chú',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              hintText: 'Lưu ý cho người bán...',
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return InkWell(
      onTap: _showPaymentOptionsSheet,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Phương thức thanh toán',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Text(
                _selectedPaymentMethod,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAmountRow('Tổng tiền hàng', _formatCurrency(_subTotal)),
          const SizedBox(height: 8),
          _buildAmountRow('Phí vận chuyển', _formatCurrency(_shippingFee)),
          const SizedBox(height: 8),
          _buildAmountRow(
            'Giảm giá phí vận chuyển',
            '-${_formatCurrency(_shippingDiscount)}',
            valueColor: Colors.green,
          ),
          const Divider(height: 24),
          _buildAmountRow(
            'Tổng thanh toán',
            _formatCurrency(_totalPayment),
            isEmphasis: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    String value, {
    Color? valueColor,
    bool isEmphasis = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isEmphasis ? 15 : 14,
            fontWeight: isEmphasis ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isEmphasis ? 18 : 14,
            fontWeight: isEmphasis ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? (isEmphasis ? Colors.teal : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 76,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng thanh toán',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Text(
                      _formatCurrency(_totalPayment),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: double.infinity,
              child: ElevatedButton(
                onPressed: placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                ),
                child: const Text(
                  'Đặt hàng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
