import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/cart_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _api = ApiService();
  final _cartService = CartService();
  Map<String, dynamic>? _product;
  bool _loading = true;
  int _qty = 1;
  bool _addingToCart = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.get('/products/${widget.productId}');
      setState(() {
        _product = res.data is Map ? res.data : res.data['data'];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _addToCart() async {
    final userId = context.read<AuthProvider>().user?.userId.toString();
    if (userId == null) {
      context.go('/login');
      return;
    }
    setState(() => _addingToCart = true);
    try {
      await _cartService.addToCart(
        userId: userId,
        productId: widget.productId,
        quantity: _qty,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm vào giỏ hàng'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _addingToCart = false);
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
        title: const Text('Chi tiết sản phẩm',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () => context.go('/cart'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.customer))
          : _product == null
              ? const Center(
                  child: Text('Không tìm thấy sản phẩm',
                      style: TextStyle(color: Colors.white54)))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            AspectRatio(
                              aspectRatio: 16 / 10,
                              child: _product!['image_url'] != null
                                  ? Image.network(_product!['image_url'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _placeholder())
                                  : _placeholder(),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category badge
                                  if (_product!['category_name'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.customer.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(_product!['category_name'],
                                          style: const TextStyle(
                                              color: AppColors.customer,
                                              fontSize: 12)),
                                    ),
                                  const SizedBox(height: 12),

                                  Text(_product!['name'] ?? '',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),

                                  if (_product!['brand'] != null)
                                    Text('Thương hiệu: ${_product!['brand']}',
                                        style: TextStyle(
                                            color: Colors.white.withOpacity(0.5),
                                            fontSize: 13)),
                                  const SizedBox(height: 16),

                                  // Price + Stock
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${_fmt(_product!['price'])}đ',
                                          style: const TextStyle(
                                              color: AppColors.success,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold)),
                                      Text(
                                        'Còn: ${_product!['stock_quantity']} sản phẩm',
                                        style: TextStyle(
                                          color: (_product!['stock_quantity'] ?? 0) < 10
                                              ? AppColors.error
                                              : Colors.white54,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Description
                                  if (_product!['description'] != null) ...[
                                    const Text('Mô tả',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    const SizedBox(height: 8),
                                    Text(_product!['description'],
                                        style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            height: 1.5)),
                                  ],
                                  // Specs
                                  if (_product!['specs'] != null && _product!['specs'] is Map && (_product!['specs'] as Map).isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    const Text('Thông số kỹ thuật',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    const SizedBox(height: 8),
                                    ...(_product!['specs'] as Map<String, dynamic>).entries.map((e) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${e.key}: ', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                                              Expanded(child: Text('${e.value}', style: const TextStyle(color: Colors.white70))),
                                            ],
                                          ),
                                        ))
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.darkCard,
                        border: Border(
                            top: BorderSide(color: Colors.white12)),
                      ),
                      child: Row(
                        children: [
                          // Quantity
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.darkCardAlt,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                                  onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                                ),
                                Text('$_qty',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                                  onPressed: () => setState(() => _qty++),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _addingToCart ? null : _addToCart,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.customer, Color(0xFF8B5CF6)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: _addingToCart
                                      ? const CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2)
                                      : const Text('Thêm vào giỏ',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.darkCard,
        child: const Center(
            child: Icon(Icons.computer_outlined, color: Colors.white24, size: 60)),
      );

  String _fmt(dynamic v) {
    final p = double.tryParse(v.toString()) ?? 0;
    return p.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}
