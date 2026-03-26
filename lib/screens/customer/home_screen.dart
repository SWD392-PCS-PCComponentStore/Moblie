import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String _search = '';
  int? _selectedCatId;

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
      ]);
      final pd = results[0].data;
      final cd = results[1].data;
      _products = pd is List ? pd : pd['data'] ?? [];
      _categories = cd is List ? cd : cd['data'] ?? [];
    } catch (_) {}
    _applyFilter();
    setState(() => _loading = false);
  }

  void _applyFilter() {
    _filtered = _products.where((p) {
      final matchSearch = _search.isEmpty ||
          (p['name'] ?? '').toLowerCase().contains(_search.toLowerCase());
      final matchCat =
          _selectedCatId == null || p['category_id'] == _selectedCatId;
      return matchSearch && matchCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkCard,
        title: const Text('PC Component Store',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            onPressed: () => context.go('/cart'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm linh kiện...',
                hintStyle: TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: AppColors.darkCard,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              onChanged: (v) {
                _search = v;
                _applyFilter();
                setState(() {});
              },
            ),
          ),

          // Category chips
          if (_categories.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CatChip(
                    label: 'Tất cả',
                    selected: _selectedCatId == null,
                    onTap: () {
                      _selectedCatId = null;
                      _applyFilter();
                      setState(() {});
                    },
                  ),
                  ..._categories.map((c) => _CatChip(
                        label: c['name'] ?? '',
                        selected: _selectedCatId == c['category_id'],
                        onTap: () {
                          _selectedCatId = c['category_id'];
                          _applyFilter();
                          setState(() {});
                        },
                      )),
                ],
              ),
            ),
          const SizedBox(height: 8),

          // Products grid
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.customer))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off, color: Colors.white24, size: 56),
                                SizedBox(height: 12),
                                Text('Không tìm thấy sản phẩm',
                                    style: TextStyle(color: Colors.white38)),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final p = _filtered[i];
                              return GestureDetector(
                                onTap: () => context.go('/home/product/${p['product_id']}'),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.darkCard,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Image
                                      Expanded(
                                        flex: 3,
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(12)),
                                          child: p['image_url'] != null
                                              ? Image.network(
                                                  p['image_url'],
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const _PlaceholderImage(),
                                                )
                                              : const _PlaceholderImage(),
                                        ),
                                      ),
                                      // Info
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(p['name'] ?? '',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis),
                                              Text(
                                                '${_fmt(p['price'])}đ',
                                                style: const TextStyle(
                                                    color: AppColors.success,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.darkCard,
        selectedItemColor: AppColors.customer,
        unselectedItemColor: Colors.white38,
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) context.go('/orders');
          if (i == 2) context.go('/profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Đơn hàng'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Hồ sơ'),
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

class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.customer : AppColors.darkCard,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.white54,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          ),
        ),
      );
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.darkCardAlt,
        child: const Center(
            child: Icon(Icons.computer_outlined, color: Colors.white24, size: 40)),
      );
}
