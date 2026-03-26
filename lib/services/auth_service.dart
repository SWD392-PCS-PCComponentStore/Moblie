import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';

export 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final ApiService _api = ApiService();

  // Đăng ký tài khoản mới
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? address,
  }) async {
    final response = await _api.post(ApiConstants.register, data: {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
    });
    return response.data;
  }

  // Đăng nhập, lưu token vào SharedPreferences
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(ApiConstants.login, data: {
      'email': email,
      'password': password,
    });

    final data = response.data;

    // Lưu token và thông tin user
    if (data['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      final user = data['user'];
      if (user != null) {
        await prefs.setString('userId', user['user_id'].toString());
        await prefs.setString('role', user['role'] ?? 'customer');
        await prefs.setString('userName', user['name'] ?? '');
        await prefs.setString('userEmail', user['email'] ?? '');
      }
    }

    return data;
  }

  // Đăng xuất, xóa token
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('role');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
  }

  // Lấy role đang đăng nhập
  Future<String?> getCurrentRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  // Kiểm tra đã đăng nhập chưa
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  // Lấy userId đang đăng nhập
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // Trả SharedPreferences instance để AuthProvider dùng
  Future<SharedPreferences> getPrefs() => SharedPreferences.getInstance();
}
