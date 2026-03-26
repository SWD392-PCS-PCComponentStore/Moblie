import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/role_scaffold.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _api = ApiService();
  List<dynamic> _users = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _roleFilter = 'Tất cả';

  final _roles = ['Tất cả', 'admin', 'shop manager', 'staff', 'customer'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/users');
      final data = res.data;
      _users = data is List ? data : data['data'] ?? [];
    } catch (_) {}
    _applyFilter();
    setState(() => _loading = false);
  }

  void _applyFilter() {
    _filtered = _users.where((u) {
      final matchSearch = _search.isEmpty ||
          (u['name'] ?? '').toLowerCase().contains(_search.toLowerCase()) ||
          (u['email'] ?? '').toLowerCase().contains(_search.toLowerCase());
      final matchRole = _roleFilter == 'Tất cả' || u['role'] == _roleFilter;
      return matchSearch && matchRole;
    }).toList();
  }

  Future<void> _deleteUser(dynamic user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: Text('Xóa tài khoản "${user['name']}"?',
            style: TextStyle(color: Colors.white.withOpacity(0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.delete('/users/${user['user_id']}');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleScaffold(
      title: 'Quản lý người dùng',
      accentColor: AppColors.admin,
      currentRoute: '/admin/users',
      navItems: adminNavItems,
      body: Column(
        children: [
          // Search + Filter bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên, email...',
                      hintStyle: TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white38),
                      filled: true,
                      fillColor: AppColors.darkCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (v) {
                      _search = v;
                      _applyFilter();
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _roleFilter,
                  dropdownColor: AppColors.darkCard,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  underline: const SizedBox(),
                  items: _roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) {
                    _roleFilter = v!;
                    _applyFilter();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.admin))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const Center(
                            child: Text('Không tìm thấy tài khoản',
                                style: TextStyle(color: Colors.white54)))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final u = _filtered[i];
                              final role = u['role'] ?? 'customer';
                              final isActive = u['status'] == 'active';
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.darkCard,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor:
                                          AppColors.roleColor(role).withOpacity(0.2),
                                      child: Icon(Icons.person,
                                          color: AppColors.roleColor(role)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(u['name'] ?? '',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600)),
                                          Text(u['email'] ?? '',
                                              style: TextStyle(
                                                  color: Colors.white.withOpacity(0.5),
                                                  fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              _RoleBadge(role),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: (isActive
                                                          ? AppColors.success
                                                          : AppColors.error)
                                                      .withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  isActive ? 'Active' : 'Inactive',
                                                  style: TextStyle(
                                                    color: isActive
                                                        ? AppColors.success
                                                        : AppColors.error,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: AppColors.error, size: 20),
                                      onPressed: () => _deleteUser(u),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge(this.role);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.roleColor(role).withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(role,
          style: TextStyle(color: AppColors.roleColor(role), fontSize: 11)),
    );
  }
}
