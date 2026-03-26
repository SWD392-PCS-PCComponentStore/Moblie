import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/role_scaffold.dart';

class StaffBuildsScreen extends StatefulWidget {
  const StaffBuildsScreen({super.key});

  @override
  State<StaffBuildsScreen> createState() => _StaffBuildsScreenState();
}

class _StaffBuildsScreenState extends State<StaffBuildsScreen> {
  final _api = ApiService();
  List<dynamic> _builds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/pc-builds');
      final data = res.data;
      _builds = data is List ? data : data['data'] ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(dynamic build) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: Text('Xóa cấu hình "${build['build_name'] ?? build['name']}"?',
            style: TextStyle(color: Colors.white.withOpacity(0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.delete('/pc-builds/${build['pc_build_id']}');
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error));
    }
  }

  void _showDetail(Map<String, dynamic> pcBuild) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _BuildDetailModal(pcBuild: pcBuild),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleScaffold(
      title: 'PC Builds',
      accentColor: AppColors.staff,
      currentRoute: '/staff/builds',
      navItems: staffNavItems,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.staff))
          : RefreshIndicator(
              onRefresh: _load,
              child: _builds.isEmpty
                  ? const Center(
                      child: Text('Chưa có cấu hình nào',
                          style: TextStyle(color: Colors.white54)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _builds.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final b = _builds[i];
                        final name = b['build_name'] ?? b['name'] ?? 'PC Build #${b['pc_build_id']}';
                        final itemCount = b['item_count'] ?? 0;
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.staff.withOpacity(0.15)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.staff.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.computer,
                                    color: AppColors.staff),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    Text('$itemCount linh kiện',
                                        style: TextStyle(
                                            color: Colors.white.withOpacity(0.5),
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined,
                                    color: AppColors.staff, size: 20),
                                onPressed: () => _showDetail(b as Map<String, dynamic>),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.error, size: 20),
                                onPressed: () => _delete(b),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _BuildDetailModal extends StatelessWidget {
  final dynamic pcBuild;
  const _BuildDetailModal({required this.pcBuild});

  @override
  Widget build(BuildContext context) {
    final items = pcBuild['items'] as List<dynamic>? ?? [];
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              pcBuild['build_name'] ?? 'Chi tiết Build',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text('Chưa có linh kiện',
                        style: TextStyle(color: Colors.white54)))
                : ListView.separated(
                    controller: ctrl,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.darkCardAlt,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.memory_outlined,
                                color: Colors.white38),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['product_name'] ?? '—',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text('SL: ${item['quantity']}',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Text(
                            '${_fmt(item['unit_price'])}đ',
                            style: const TextStyle(
                                color: AppColors.success, fontSize: 13),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _fmt(dynamic v) {
    final p = double.tryParse(v.toString()) ?? 0;
    return p.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}
