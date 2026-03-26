import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/role_scaffold.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _api = ApiService();
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.get('/users');
      final data = res.data;
      setState(() {
        _users = data is List ? data : data['data'] ?? [];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Map<String, int> get _roleCounts {
    final counts = {'admin': 0, 'shop manager': 0, 'staff': 0, 'customer': 0};
    for (final u in _users) {
      final role = (u['role'] ?? 'customer').toString().toLowerCase();
      if (counts.containsKey(role)) counts[role] = (counts[role] ?? 0) + 1;
    }
    return counts;
  }

  int get _activeCount =>
      _users.where((u) => u['status'] == 'active').length;

  @override
  Widget build(BuildContext context) {
    final counts = _roleCounts;
    final recent = _users.take(5).toList();

    return RoleScaffold(
      title: 'Admin Dashboard',
      accentColor: AppColors.admin,
      currentRoute: '/admin',
      navItems: adminNavItems,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.admin))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Subtitle
                  Text(
                    '$_activeCount/${_users.length} tài khoản đang hoạt động',
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 16),

                  // Stat Cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _StatCard('Tổng tài khoản', _users.length.toString(), Icons.people, AppColors.admin),
                      _StatCard('Admin', counts['admin'].toString(), Icons.shield_outlined, AppColors.warning),
                      _StatCard('Manager', counts['shop manager'].toString(), Icons.work_outline, const Color(0xFFF97316)),
                      _StatCard('Staff', counts['staff'].toString(), Icons.support_agent_outlined, AppColors.info),
                      _StatCard('Customer', counts['customer'].toString(), Icons.person_outline, AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent users table
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tài khoản mới nhất',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton(
                        onPressed: () => context.go('/admin/users'),
                        child: const Text('Xem tất cả', style: TextStyle(color: AppColors.admin)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: recent.isEmpty
                          ? [const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('Không có dữ liệu', style: TextStyle(color: Colors.white54)),
                            )]
                          : recent.map((u) => _UserRow(u)).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final dynamic user;
  const _UserRow(this.user);

  @override
  Widget build(BuildContext context) {
    final role = user['role'] ?? 'customer';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.roleColor(role).withOpacity(0.2),
            child: Icon(Icons.person, color: AppColors.roleColor(role), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                Text(user['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.roleColor(role).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(role, style: TextStyle(color: AppColors.roleColor(role), fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
