import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/build_request_model.dart';
import '../../services/api_service.dart';
import '../../widgets/role_scaffold.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final _api = ApiService();
  List<BuildRequestModel> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/staff-build-requests');
      final data = res.data;
      final list = data is List ? data : data['data'] ?? [];
      _requests = list.map<BuildRequestModel>((e) => BuildRequestModel.fromJson(e)).toList();
    } catch (_) {}
    setState(() => _loading = false);
  }

  int _countByStatus(String s) =>
      _requests.where((r) => r.status == s).length;

  @override
  Widget build(BuildContext context) {
    final recent = _requests.take(5).toList();

    return RoleScaffold(
      title: 'Staff Dashboard',
      accentColor: AppColors.staff,
      currentRoute: '/staff',
      navItems: staffNavItems,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.staff))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stat Cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _StatCard('Tổng requests', _requests.length.toString(),
                          Icons.list_alt_outlined, AppColors.staff),
                      _StatCard('Chờ duyệt', _countByStatus('pending').toString(),
                          Icons.hourglass_empty, AppColors.warning),
                      _StatCard('Đang xử lý', _countByStatus('in_progress').toString(),
                          Icons.build_circle_outlined, AppColors.admin),
                      _StatCard('Hoàn thành', _countByStatus('completed').toString(),
                          Icons.check_circle_outline, AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent requests
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Requests gần đây',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      TextButton(
                        onPressed: () => context.go('/staff/requests'),
                        child: const Text('Xem tất cả',
                            style: TextStyle(color: AppColors.staff)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: recent.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Chưa có request',
                                style: TextStyle(color: Colors.white54)))
                        : Column(
                            children: recent.map((r) => _RequestRow(r)).toList(),
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
  Widget build(BuildContext context) => Container(
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
                Text(value,
                    style: TextStyle(
                        color: color, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 12)),
              ],
            ),
          ],
        ),
      );
}

class _RequestRow extends StatelessWidget {
  final BuildRequestModel request;
  const _RequestRow(this.request);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${request.requestId} — ${request.customerName ?? 'Khách'}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w500)),
                  Text(
                    'Ngân sách: ${request.budgetRange != null ? "${request.budgetRange!.toStringAsFixed(0)}đ" : "Chưa xác định"}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.buildRequestStatusColor(request.status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(request.status,
                  style: TextStyle(
                      color: AppColors.buildRequestStatusColor(request.status),
                      fontSize: 11)),
            ),
          ],
        ),
      );
}
