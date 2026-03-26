import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  String get role => _user?.role ?? 'customer';
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isManager => _user?.isManager ?? false;
  bool get isStaff => _user?.isStaff ?? false;
  bool get isCustomer => _user?.isCustomer ?? false;

  // Khởi tạo: kiểm tra session đã lưu
  Future<void> init() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      final prefs = await _authService.getPrefs();
      _user = UserModel(
        userId: int.tryParse(prefs.getString('userId') ?? '0') ?? 0,
        name: prefs.getString('userName') ?? '',
        email: prefs.getString('userEmail') ?? '',
        role: prefs.getString('role') ?? 'customer',
        status: 'active',
      );
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.login(email: email, password: password);
      if (data['user'] != null) {
        _user = UserModel.fromJson(data['user']);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('401') || msg.contains('Invalid')) return 'Email hoặc mật khẩu không đúng';
    if (msg.contains('400') || msg.contains('exists')) return 'Email đã tồn tại';
    if (msg.contains('connection')) return 'Không thể kết nối đến server';
    return 'Đã có lỗi xảy ra, vui lòng thử lại';
  }
}
