import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/role_scaffold.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  final _api = ApiService();
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  List<dynamic> _promotions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.get('/products'),
        _api.get('/categories'),
        _api.get('/promotions'),
      ]);
      final pd = results[0].data;
      final cd = results[1].data;
      final prd = results[2].data;
      _products = pd is List ? pd : pd['data'] ?? [];
      _categories = cd is List ? cd : cd['data'] ?? [];
      _promotions = prd is List ? prd : prd['data'] ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  List<dynamic> get _lowStock =>
      _products.where((p) => (p['stock_quantity'] ?? 0) < 10).toList();

  @override
  Widget build(BuildContext context) {
    return RoleScaffold(
      title: 'Manager Dashboard',
      accentColor: AppColors.manager,
      currentRoute: '/manager',
      navItems: managerNavItems,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.manager))
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
                      _StatCard('Tổng sản phẩm', _products.length.toString(),
                          Icons.inventory_2_outlined, AppColors.manager),
                      _StatCard('Danh mục', _categories.length.toString(),
                          Icons.category_outlined, AppColors.info),
                      _StatCard('Khuyến mãi', _promotions.length.toString(),
                          Icons.local_offer_outlined, AppColors.success),
                      _StatCard('Sắp hết hàng', _lowStock.length.toString(),
                          Icons.warning_amber_outlined, AppColors.error),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Low stock table
                  const Text('Sản phẩm sắp hết hàng',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _lowStock.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('Tất cả sản phẩm còn đủ hàng',
                                style: TextStyle(color: Colors.white54)),
                          )
                        : Column(
                            children: _lowStock.take(5).map((p) {
                              return ListTile(
                                title: Text(p['name'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14)),
                                subtitle: Text('Tồn: ${p['stock_quantity']}',
                                    style: const TextStyle(
                                        color: AppColors.error, fontSize: 12)),
                                trailing: Text(
                                  '${_formatPrice(p['price'])} đ',
                                  style: const TextStyle(
                                      color: AppColors.success, fontSize: 13),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Categories + Promotions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _InfoCard(
                          title: 'Danh mục (${_categories.length})',
                          onTap: () => context.go('/manager/categories'),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _categories.take(6).map((c) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.manager.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(c['name'] ?? '',
                                    style: const TextStyle(
                                        color: AppColors.manager, fontSize: 12)),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          title: 'Khuyến mãi (${_promotions.length})',
                          onTap: () => context.go('/manager/promotions'),
                          child: Column(
                            children: _promotions.take(5).map((p) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(p['code'] ?? '',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12)),
                                    Text('-${p['discount_percent']}%',
                                        style: const TextStyle(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  String _formatPrice(dynamic price) {
    final p = double.tryParse(price.toString()) ?? 0;
    return p.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
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
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onTap;
  const _InfoCard({required this.title, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              if (onTap != null)
                GestureDetector(
                  onTap: onTap,
                  child: const Icon(Icons.arrow_forward_ios,
                      color: Colors.white38, size: 14),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
