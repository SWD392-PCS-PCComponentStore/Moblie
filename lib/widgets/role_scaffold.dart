import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';

class RoleScaffold extends StatelessWidget {
  final String title;
  final Color accentColor;
  final Widget body;
  final List<_NavItem> navItems;
  final String currentRoute;
  final List<Widget>? actions;

  const RoleScaffold({
    super.key,
    required this.title,
    required this.accentColor,
    required this.body,
    required this.navItems,
    required this.currentRoute,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkCard,
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          ...(actions ?? []),
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
            color: AppColors.darkCard,
            onSelected: (val) async {
              if (val == 'logout') {
                await context.read<AuthProvider>().logout();
                if (context.mounted) context.go('/login');
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                child: Consumer<AuthProvider>(
                  builder: (_, auth, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.user?.name ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(auth.user?.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Text('Đăng xuất', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.darkCard,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.white38,
        currentIndex: navItems.indexWhere((e) => e.route == currentRoute).clamp(0, navItems.length - 1),
        onTap: (i) => context.go(navItems[i].route),
        items: navItems
            .map((e) => BottomNavigationBarItem(icon: Icon(e.icon), label: e.label))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final String label;
  const _NavItem(this.route, this.icon, this.label);
}

// Tiện ích tạo các nav items cho từng role
List<_NavItem> get adminNavItems => const [
      _NavItem('/admin', Icons.dashboard_outlined, 'Dashboard'),
      _NavItem('/admin/users', Icons.people_outline, 'Người dùng'),
      _NavItem('/manager/orders', Icons.receipt_long_outlined, 'Đơn hàng'),
    ];

List<_NavItem> get managerNavItems => const [
      _NavItem('/manager', Icons.dashboard_outlined, 'Dashboard'),
      _NavItem('/manager/products', Icons.inventory_2_outlined, 'Sản phẩm'),
      _NavItem('/manager/categories', Icons.category_outlined, 'Danh mục'),
      _NavItem('/manager/promotions', Icons.local_offer_outlined, 'KM'),
      _NavItem('/manager/orders', Icons.receipt_long_outlined, 'Đơn hàng'),
    ];

List<_NavItem> get staffNavItems => const [
      _NavItem('/staff', Icons.dashboard_outlined, 'Dashboard'),
      _NavItem('/staff/requests', Icons.build_circle_outlined, 'Requests'),
      _NavItem('/staff/builds', Icons.computer_outlined, 'PC Builds'),
    ];
