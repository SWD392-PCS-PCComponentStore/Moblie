import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// Auth
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';

// Customer
import '../screens/customer/home_screen.dart';
import '../screens/customer/product_detail_screen.dart';
import '../screens/customer/cart_screen.dart';
import '../screens/customer/checkout_screen.dart';
import '../screens/customer/orders_screen.dart';
import '../screens/customer/profile_screen.dart';

// Admin
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_users_screen.dart';

// Manager
import '../screens/manager/manager_dashboard_screen.dart';
import '../screens/manager/manager_products_screen.dart';
import '../screens/manager/manager_categories_screen.dart';
import '../screens/manager/manager_promotions_screen.dart';
import '../screens/manager/manager_orders_screen.dart';

// Staff
import '../screens/staff/staff_dashboard_screen.dart';
import '../screens/staff/staff_requests_screen.dart';
import '../screens/staff/staff_builds_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) {
        return _homeByRole(authProvider.role);
      }
      return null;
    },
    refreshListenable: authProvider,
    routes: [
      // ── Auth ──────────────────────────────────────────────
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // ── Customer ──────────────────────────────────────────
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'product/:id',
            builder: (_, state) =>
                ProductDetailScreen(productId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),

      // ── Admin ─────────────────────────────────────────────
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),

      // ── Manager ───────────────────────────────────────────
      GoRoute(path: '/manager', builder: (_, __) => const ManagerDashboardScreen()),
      GoRoute(path: '/manager/products', builder: (_, __) => const ManagerProductsScreen()),
      GoRoute(path: '/manager/categories', builder: (_, __) => const ManagerCategoriesScreen()),
      GoRoute(path: '/manager/promotions', builder: (_, __) => const ManagerPromotionsScreen()),
      GoRoute(path: '/manager/orders', builder: (_, __) => const ManagerOrdersScreen()),

      // ── Staff ─────────────────────────────────────────────
      GoRoute(path: '/staff', builder: (_, __) => const StaffDashboardScreen()),
      GoRoute(path: '/staff/requests', builder: (_, __) => const StaffRequestsScreen()),
      GoRoute(path: '/staff/builds', builder: (_, __) => const StaffBuildsScreen()),
    ],
  );
}

String _homeByRole(String role) {
  switch (role) {
    case 'admin': return '/admin';
    case 'shop manager': return '/manager';
    case 'staff': return '/staff';
    default: return '/home';
  }
}
