import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/role_scaffold.dart';

class ManagerCategoriesScreen extends StatefulWidget {
  const ManagerCategoriesScreen({super.key});

  @override
  State<ManagerCategoriesScreen> createState() => _ManagerCategoriesScreenState();
}

class _ManagerCategoriesScreenState extends State<ManagerCategoriesScreen> {
  final _api = ApiService();
  List<dynamic> _cats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/categories');
      final data = res.data;
      _cats = data is List ? data : data['data'] ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showModal([dynamic cat]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CatModal(cat: cat, onSaved: _load),
    );
  }

  Future<void> _delete(dynamic cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: Text('Xóa danh mục "${cat['name']}"?',
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
      await _api.delete('/categories/${cat['category_id']}');
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleScaffold(
      title: 'Quản lý danh mục',
      accentColor: AppColors.manager,
      currentRoute: '/manager/categories',
      navItems: managerNavItems,
      actions: [
        IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showModal()),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.manager))
          : RefreshIndicator(
              onRefresh: _load,
              child: _cats.isEmpty
                  ? const Center(
                      child: Text('Chưa có danh mục',
                          style: TextStyle(color: Colors.white54)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 360,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                      ),
                      itemCount: _cats.length,
                      itemBuilder: (_, i) {
                        final c = _cats[i];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.manager.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(c['name'] ?? '',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                  ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                          onTap: () => _showModal(c),
                                          child: const Icon(Icons.edit_outlined,
                                              color: AppColors.manager, size: 18)),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                          onTap: () => _delete(c),
                                          child: const Icon(Icons.delete_outline,
                                              color: AppColors.error, size: 18)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('ID: ${c['category_id']}',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 11)),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(c['description'] ?? 'Không có mô tả',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 12),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis),
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

class _CatModal extends StatefulWidget {
  final dynamic cat;
  final VoidCallback onSaved;
  const _CatModal({this.cat, required this.onSaved});

  @override
  State<_CatModal> createState() => _CatModalState();
}

class _CatModalState extends State<_CatModal> {
  final _api = ApiService();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.cat != null) {
      _nameCtrl.text = widget.cat['name'] ?? '';
      _descCtrl.text = widget.cat['description'] ?? '';
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    final data = {'name': _nameCtrl.text, 'description': _descCtrl.text};
    try {
      if (widget.cat == null) {
        await _api.post('/categories', data: data);
      } else {
        await _api.put('/categories/${widget.cat['category_id']}', data: data);
      }
      if (mounted) Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error));
    }
    setState(() => _loading = false);
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        filled: true,
        fillColor: AppColors.darkCardAlt,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.cat == null ? 'Thêm danh mục' : 'Sửa danh mục',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _deco('Tên danh mục *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: _deco('Mô tả (tùy chọn)'),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _loading ? null : _save,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.manager,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
