import 'api_service.dart';
import '../constants/api_constants.dart';

class CartService {
  final ApiService _api = ApiService();

  // Lấy giỏ hàng của user
  Future<Map<String, dynamic>> getCart(String userId) async {
    final response = await _api.get(ApiConstants.cart(userId));
    return response.data;
  }

  // Lấy tổng tiền giỏ hàng
  Future<Map<String, dynamic>> getCartTotal(String userId) async {
    final response = await _api.get(ApiConstants.cartTotal(userId));
    return response.data;
  }

  // Thêm sản phẩm vào giỏ hàng
  Future<Map<String, dynamic>> addToCart({
    required String userId,
    required String productId,
    required int quantity,
  }) async {
    final response = await _api.post(ApiConstants.cartAdd(userId), data: {
      'product_id': productId,
      'quantity': quantity,
    });
    return response.data;
  }

  // Cập nhật số lượng sản phẩm trong giỏ
  Future<Map<String, dynamic>> updateCartItem({
    required String cartId,
    required int quantity,
  }) async {
    final response = await _api.put(ApiConstants.cartUpdate(cartId), data: {
      'quantity': quantity,
    });
    return response.data;
  }

  // Xóa sản phẩm khỏi giỏ hàng
  Future<Map<String, dynamic>> removeFromCart(String cartId) async {
    final response = await _api.delete(ApiConstants.cartRemove(cartId));
    return response.data;
  }

  // Xóa toàn bộ giỏ hàng
  Future<Map<String, dynamic>> clearCart(String userId) async {
    final response = await _api.delete(ApiConstants.cartClear(userId));
    return response.data;
  }
}
