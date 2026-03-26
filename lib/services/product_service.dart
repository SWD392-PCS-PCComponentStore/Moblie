import 'api_service.dart';
import '../constants/api_constants.dart';

class ProductService {
  final ApiService _api = ApiService();

  // Lấy tất cả sản phẩm (có thể filter/search qua query params)
  Future<List<dynamic>> getProducts({
    String? search,
    String? sort,
    int? page,
    int? limit,
  }) async {
    final response = await _api.get(ApiConstants.products, params: {
      if (search != null) 'search': search,
      if (sort != null) 'sort': sort,
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
    });
    final data = response.data;
    if (data is List) return data;
    return data['data'] ?? data['products'] ?? [];
  }

  // Lấy sản phẩm theo ID
  Future<Map<String, dynamic>> getProductById(String id) async {
    final response = await _api.get(ApiConstants.productById(id));
    return response.data;
  }

  // Lấy sản phẩm theo danh mục
  Future<List<dynamic>> getProductsByCategory(String categoryId) async {
    final response =
        await _api.get(ApiConstants.productsByCategory(categoryId));
    final data = response.data;
    if (data is List) return data;
    return data['data'] ?? data['products'] ?? [];
  }
}
