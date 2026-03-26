import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _cartService = CartService();
  final _orderService = OrderService();
  final _addrCtrl = TextEditingController();
  final _promoCtrl = TextEditingController();
  String _paymentMethod = 'COD';
  bool _loading = false;
  List<dynamic> _cartItems = [];
  double _total = 0;

  final _paymentMethods = [
    {'value': 'COD', 'label': 'Thanh toán khi nhận hàng (COD)'},
    {'value': 'QR_FULL', 'label': 'Thanh toán QR toàn bộ'},
    {'value': 'QR_INSTALLMENT', 'label': 'Thanh toán QR trả góp'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final userId = context.read<AuthProvider>().user?.userId.toString();
    if (userId == null) return;
    try {
      final cartData = await _cartService.getCart(userId);
      final totalData = await _cartService.getCartTotal(userId);
      setState(() {
        _cartItems = cartData['items'] as List<dynamic>? ?? [];
        _total = double.tryParse(totalData['total']?.toString() ?? '0') ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _placeOrder() async {
    if (_addrCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng nhập địa chỉ giao hàng'),
            backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await _orderService.checkout(
        paymentMethod: _paymentMethod,
        shippingAddress: _addrCtrl.text,
        promotionCode:
            _promoCtrl.text.isEmpty ? null : _promoCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Đặt hàng thành công!'),
              backgroundColor: AppColors.success),
        );
        context.go('/orders');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkCard,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/cart'),
        ),
        title: const Text('Đặt hàng', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shipping address
            _SectionTitle('Địa chỉ giao hàng'),
            const SizedBox(height: 10),
            TextField(
              controller: _addrCtrl,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco('Nhập địa chỉ nhận hàng *'),
            ),
            const SizedBox(height: 20),

            // Payment method
            _SectionTitle('Phương thức thanh toán'),
            const SizedBox(height: 10),
            ..._paymentMethods.map((m) => RadioListTile<String>(
                  value: m['value']!,
                  groupValue: _paymentMethod,
                  title: Text(m['label']!,
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                  activeColor: AppColors.customer,
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                  tileColor: AppColors.darkCard,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                )),
            const SizedBox(height: 20),

            // Promo code
            _SectionTitle('Mã khuyến mãi (tùy chọn)'),
            const SizedBox(height: 10),
            TextField(
              controller: _promoCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDeco('Nhập mã giảm giá'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 20),

            // Order summary
            _SectionTitle('Tóm tắt đơn hàng'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ..._cartItems.take(3).map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['product_name'] ?? item['build_name'] ?? 'Sản phẩm',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text('x${item['quantity']}',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 12)),
                          ],
                        ),
                      )),
                  if (_cartItems.length > 3)
                    Text('...và ${_cartItems.length - 3} sản phẩm khác',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  const Divider(color: Colors.white12, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng cộng',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('${_fmt(_total)}đ',
                          style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            GestureDetector(
              onTap: _loading ? null : _placeOrder,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.customer, Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5)
                      : const Text('Xác nhận đặt hàng',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _SectionTitle(String title) => Text(title,
      style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15));

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      );

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}
