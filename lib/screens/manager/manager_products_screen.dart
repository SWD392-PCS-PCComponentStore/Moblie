import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/role_scaffold.dart';

class ManagerProductsScreen extends StatefulWidget {
  const ManagerProductsScreen({super.key});

  @override
  State<ManagerProductsScreen> createState() => _ManagerProductsScreenState();
}

class _ManagerProductsScreenState extends State<ManagerProductsScreen> {
  final _api = ApiService();
  List<dynamic> _products = [];
  List<dynamic> _filtered = [];
  List<dynamic> _categories = [];
  bool _loading = true;
  String _search = '';
  String _catFilter = 'Tất cả';

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
          _catFilter == 'Tất cả' || p['category_name'] == _catFilter;
      return matchSearch && matchCat;
    }).toList();
  }

  Future<void> _delete(dynamic product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: Text('Xóa sản phẩm "${product['name']}"?',
            style: TextStyle(color: Colors.white.withOpacity(0.7))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.delete('/products/${product['product_id']}');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAddEditModal([dynamic product]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ProductFormModal(
        product: product,
        categories: _categories,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catNames = ['Tất cả', ..._categories.map((c) => c['name'].toString())];
    return RoleScaffold(
      title: 'Quản lý sản phẩm',
      accentColor: AppColors.manager,
      currentRoute: '/manager/products',
      navItems: managerNavItems,
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () => _showAddEditModal(),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tìm sản phẩm...',
                      hintStyle: TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white38),
                      filled: true,
                      fillColor: AppColors.darkCard,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (v) {
                      _search = v;
                      _applyFilter();
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _catFilter,
                  dropdownColor: AppColors.darkCard,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  underline: const SizedBox(),
                  items: catNames
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    _catFilter = v!;
                    _applyFilter();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.manager))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const Center(
                            child: Text('Không tìm thấy sản phẩm',
                                style: TextStyle(color: Colors.white54)))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final p = _filtered[i];
                              final lowStock = (p['stock_quantity'] ?? 0) < 10;
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.darkCard,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    // Thumbnail
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.darkCardAlt,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: p['image_url'] != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(p['image_url'],
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(Icons.image_outlined,
                                                          color: Colors.white38)),
                                            )
                                          : const Icon(Icons.inventory_2_outlined,
                                              color: Colors.white38),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(p['name'] ?? '',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              _Badge(
                                                  p['category_name'] ?? 'N/A',
                                                  AppColors.manager),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${_fmt(p['price'])}đ',
                                                style: const TextStyle(
                                                    color: AppColors.success,
                                                    fontSize: 12),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Tồn: ${p['stock_quantity']}',
                                                style: TextStyle(
                                                    color: lowStock
                                                        ? AppColors.error
                                                        : Colors.white54,
                                                    fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              color: AppColors.manager, size: 18),
                                          onPressed: () => _showAddEditModal(p),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: AppColors.error, size: 18),
                                          onPressed: () => _delete(p),
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
        ],
      ),
    );
  }

  String _fmt(dynamic price) {
    final p = double.tryParse(price.toString()) ?? 0;
    return p.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 10)),
      );
}

class _ProductFormModal extends StatefulWidget {
  final dynamic product;
  final List<dynamic> categories;
  final VoidCallback onSaved;

  const _ProductFormModal({this.product, required this.categories, required this.onSaved});

  @override
  State<_ProductFormModal> createState() => _ProductFormModalState();
}

class _ProductFormModalState extends State<_ProductFormModal> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imgCtrl = TextEditingController();
  int? _categoryId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product;
      _nameCtrl.text = p['name'] ?? '';
      _priceCtrl.text = p['price']?.toString() ?? '';
      _stockCtrl.text = p['stock_quantity']?.toString() ?? '';
      _brandCtrl.text = p['brand'] ?? '';
      _descCtrl.text = p['description'] ?? '';
      _imgCtrl.text = p['image_url'] ?? '';
      _categoryId = p['category_id'];
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final data = {
      'name': _nameCtrl.text,
      'price': double.tryParse(_priceCtrl.text) ?? 0,
      'stock_quantity': int.tryParse(_stockCtrl.text) ?? 0,
      if (_brandCtrl.text.isNotEmpty) 'brand': _brandCtrl.text,
      if (_descCtrl.text.isNotEmpty) 'description': _descCtrl.text,
      if (_imgCtrl.text.isNotEmpty) 'image_url': _imgCtrl.text,
      if (_categoryId != null) 'category_id': _categoryId,
    };
    try {
      if (widget.product == null) {
        await _api.post('/products', data: data);
      } else {
        await _api.put('/products/${widget.product['product_id']}', data: data);
      }
      if (mounted) Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
      );
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              _field(_nameCtrl, 'Tên sản phẩm *',
                  validator: (v) => v!.isEmpty ? 'Bắt buộc' : null),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _field(_priceCtrl, 'Giá *',
                          keyboard: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Bắt buộc' : null)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_stockCtrl, 'Tồn kho', keyboard: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              _field(_brandCtrl, 'Thương hiệu'),
              const SizedBox(height: 12),
              _field(_imgCtrl, 'URL ảnh'),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _categoryId,
                dropdownColor: AppColors.darkCardAlt,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco('Danh mục'),
                items: widget.categories
                    .map((c) => DropdownMenuItem<int>(
                        value: c['category_id'], child: Text(c['name'] ?? '')))
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 12),
              _field(_descCtrl, 'Mô tả', maxLines: 3),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _loading ? null : _save,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [AppColors.manager, AppColors.manager.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : Text(isEdit ? 'Lưu thay đổi' : 'Thêm sản phẩm',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType? keyboard, String? Function(String?)? validator, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDeco(label),
      validator: validator,
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        filled: true,
        fillColor: AppColors.darkCardAlt,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        errorStyle: const TextStyle(color: AppColors.error),
      );
}
