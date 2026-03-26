import 'api_service.dart';
import '../constants/api_constants.dart';

class CategoryService {
  final ApiService _api = ApiService();

  // Lấy tất cả danh mục
  Future<List<dynamic>> getCategories() async {
    final response = await _api.get(ApiConstants.categories);
    final data = response.data;
    if (data is List) return data;
    return data['data'] ?? data['categories'] ?? [];
  }

  // Lấy danh mục theo ID
  Future<Map<String, dynamic>> getCategoryById(String id) async {
    final response = await _api.get(ApiConstants.categoryById(id));
    return response.data;
  }
}
