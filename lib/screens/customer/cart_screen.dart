import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../models/cart_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cartService = CartService();
  List<CartItemModel> _items = [];
  bool _loading = true;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().user?.userId.toString();
    if (userId == null) return;
    setState(() => _loading = true);
    try {
      final cartData = await _cartService.getCart(userId);
      final list = cartData['items'] as List<dynamic>? ?? [];
      _items = list.map((e) => CartItemModel.fromJson(e)).toList();
      final totalData = await _cartService.getCartTotal(userId);
      _total = double.tryParse(totalData['total']?.toString() ?? '0') ?? 0;
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _remove(CartItemModel item) async {
    try {
      await _cartService.removeFromCart(item.cartItemId.toString());
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _updateQty(CartItemModel item, int qty) async {
    try {
      await _cartService.updateCartItem(
          cartId: item.cartItemId.toString(), quantity: qty);
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkCard,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Giỏ hàng', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.customer))
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_cart_outlined,
                          color: Colors.white24, size: 64),
                      const SizedBox(height: 16),
                      const Text('Giỏ hàng trống',
                          style: TextStyle(color: Colors.white54, fontSize: 16)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.go('/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.customer,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Mua sắm ngay',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final item = _items[i];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.darkCard,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppColors.darkCardAlt,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: item.imageUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(item.imageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(Icons.image_outlined,
                                                        color: Colors.white38)),
                                          )
                                        : const Icon(Icons.computer_outlined,
                                            color: Colors.white38),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.displayName,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text('${_fmt(item.unitPrice)}đ',
                                            style: const TextStyle(
                                                color: AppColors.success,
                                                fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: item.quantity > 1
                                                ? () => _updateQty(
                                                    item, item.quantity - 1)
                                                : null,
                                            child: const Icon(Icons.remove_circle_outline,
                                                color: Colors.white54, size: 20),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            child: Text('${item.quantity}',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold)),
                                          ),
                                          GestureDetector(
                                            onTap: () =>
                                                _updateQty(item, item.quantity + 1),
                                            child: const Icon(Icons.add_circle_outline,
                                                color: Colors.white54, size: 20),
                                          ),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () => _remove(item),
                                        style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(0, 0)),
                                        child: const Text('Xóa',
                                            style: TextStyle(
                                                color: AppColors.error,
                                                fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Checkout bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.darkCard,
                        border: Border(top: BorderSide(color: Colors.white12)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Tổng cộng',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.6))),
                                Text('${_fmt(_total)}đ',
                                    style: const TextStyle(
                                        color: AppColors.success,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/checkout'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.customer, Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('Đặt hàng',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}
