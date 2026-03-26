import 'api_service.dart';
import '../constants/api_constants.dart';

class OrderService {
  final ApiService _api = ApiService();

  // Lấy danh sách đơn hàng của tôi
  Future<List<dynamic>> getMyOrders() async {
    final response = await _api.get(ApiConstants.myOrders);
    final data = response.data;
    if (data is List) return data;
    return data['data'] ?? data['orders'] ?? [];
  }

  // Lấy chi tiết đơn hàng theo ID
  Future<Map<String, dynamic>> getOrderById(String id) async {
    final response = await _api.get(ApiConstants.orderById(id));
    return response.data;
  }

  // Checkout: tạo đơn hàng từ giỏ hàng
  Future<Map<String, dynamic>> checkout({
    String? promotionCode,
    String? paymentMethod,
    String? shippingAddress,
  }) async {
    final response = await _api.post(ApiConstants.checkout, data: {
      if (promotionCode != null) 'promotion_code': promotionCode,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (shippingAddress != null) 'shipping_address': shippingAddress,
    });
    return response.data;
  }
}
