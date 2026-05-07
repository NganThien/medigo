class OrderService {
  static final List<Map<String, dynamic>> _orders = [];

  static void addOrder(Map<String, dynamic> order) {
    _orders.insert(0, order);
  }

  static List<Map<String, dynamic>> getAllOrders() {
    return List<Map<String, dynamic>>.from(_orders);
  }
}

