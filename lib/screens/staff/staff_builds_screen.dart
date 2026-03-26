import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
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
  bool _showCreate = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/pc-builds');
      final data = res.data;
      _builds = data is List ? data : data['data'] ?? [];
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(dynamic b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: Text('Xóa cấu hình "${b['build_name'] ?? 'này'}"?', style: TextStyle(color: Colors.white.withOpacity(0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.delete('/pc-builds/${b['pc_build_id']}');
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error));
    }
  }

  void _showDetail(Map<String, dynamic> b) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _BuildDetailModal(pcBuild: b),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleScaffold(
      title: _showCreate ? 'Tạo cấu hình PC' : 'PC Builds',
      accentColor: AppColors.staff,
      currentRoute: '/staff/builds',
      navItems: staffNavItems,
      actions: [
        if (!_showCreate)
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'Tạo cấu hình mới',
            onPressed: () => setState(() => _showCreate = true),
          ),
        if (_showCreate)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => setState(() => _showCreate = false),
          ),
      ],
      body: _showCreate
          ? _CreateBuildPanel(api: _api, onCreated: () { setState(() => _showCreate = false); _load(); })
          : _BuildListView(builds: _builds, loading: _loading, onRefresh: _load, onView: _showDetail, onDelete: _delete),
    );
  }
}

// ─── Build List ───────────────────────────────────────────────────────────────

class _BuildListView extends StatelessWidget {
  final List<dynamic> builds;
  final bool loading;
  final Future<void> Function() onRefresh;
  final void Function(Map<String, dynamic>) onView;
  final void Function(dynamic) onDelete;
  const _BuildListView({required this.builds, required this.loading, required this.onRefresh, required this.onView, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppColors.staff));
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: builds.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.computer_outlined, color: Colors.white24, size: 64),
              const SizedBox(height: 12),
              const Text('Chưa có cấu hình nào', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.add, color: AppColors.staff),
                label: const Text('Tạo cấu hình đầu tiên', style: TextStyle(color: AppColors.staff)),
                onPressed: () {},
              ),
            ]))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: builds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final b = builds[i];
                final name = b['build_name'] ?? 'PC Build #${b['pc_build_id']}';
                final itemCount = b['item_count'] ?? 0;
                final total = double.tryParse(b['total_price']?.toString() ?? '0') ?? 0;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.staff.withOpacity(0.15)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: AppColors.staff.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.computer, color: AppColors.staff),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('$itemCount linh kiện', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      if (total > 0) Text('${_fmt(total)}đ', style: const TextStyle(color: AppColors.success, fontSize: 12)),
                    ])),
                    IconButton(icon: const Icon(Icons.visibility_outlined, color: AppColors.staff, size: 20), onPressed: () => onView(b as Map<String, dynamic>)),
                    IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20), onPressed: () => onDelete(b)),
                  ]),
                );
              },
            ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

// ─── Create Build Panel ───────────────────────────────────────────────────────

class _CreateBuildPanel extends StatefulWidget {
  final ApiService api;
  final VoidCallback onCreated;
  const _CreateBuildPanel({required this.api, required this.onCreated});
  @override
  State<_CreateBuildPanel> createState() => _CreateBuildPanelState();
}

class _CreateBuildPanelState extends State<_CreateBuildPanel> {
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  bool _loadingProds = true;
  bool _submitting = false;

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int? _selectedCatId;

  final Map<String, Map<String, dynamic>?> _slots = {
    'CPU': null, 'GPU': null, 'RAM': null, 'Storage': null,
    'Mainboard': null, 'PSU': null, 'Case': null, 'Cooling': null,
  };

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([widget.api.get('/products'), widget.api.get('/categories')]);
      final pd = results[0].data; final cd = results[1].data;
      _products = pd is List ? pd : pd['data'] ?? [];
      _categories = cd is List ? cd : cd['data'] ?? [];
    } catch (_) {}
    setState(() => _loadingProds = false);
  }

  double get _total => _slots.values.where((v) => v != null).fold(0.0, (s, v) => s + (double.tryParse(v!['price'].toString()) ?? 0));

  List<dynamic> _slotProducts(String slot) {
    final keys = const {
      'CPU': ['cpu','processor'], 'GPU': ['gpu','vga','graphic'],
      'RAM': ['ram','memory'], 'Storage': ['ssd','hdd','storage','nvme'],
      'Mainboard': ['mainboard','motherboard'], 'PSU': ['psu','nguồn','power'],
      'Case': ['case','vỏ'], 'Cooling': ['cooling','tản nhiệt','cooler'],
    }[slot] ?? <String>[];
    final filtered = _products.where((p) {
      final n = (p['name'] ?? '').toLowerCase();
      final c = (p['category_name'] ?? '').toLowerCase();
      return keys.any((k) => n.contains(k) || c.contains(k));
    }).toList();
    return filtered.isNotEmpty ? filtered : _products;
  }

  void _pickProduct(String slot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _ProductPickerSheet(
        slot: slot, products: _slotProducts(slot), selected: _slots[slot],
        onSelect: (p) { setState(() => _slots[slot] = p); Navigator.pop(context); },
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên cấu hình'), backgroundColor: AppColors.error));
      return;
    }
    final items = _slots.entries.where((e) => e.value != null).map((e) => {'product_id': e.value!['product_id'], 'quantity': 1}).toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ít nhất 1 linh kiện'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.api.post('/pc-builds', data: {
        'build_name': name,
        if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
        if (_selectedCatId != null) 'category_id': _selectedCatId,
        'items': items,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã tạo cấu hình PC!'), backgroundColor: AppColors.success));
      widget.onCreated();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error));
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProds) return const Center(child: CircularProgressIndicator(color: AppColors.staff));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Form info
        const Text('Thông tin cấu hình', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        _Field(controller: _nameCtrl, label: 'Tên cấu hình PC *'),
        const SizedBox(height: 10),
        _Field(controller: _descCtrl, label: 'Mô tả (tuỳ chọn)', maxLines: 2),
        const SizedBox(height: 10),
        if (_categories.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(10)),
            child: DropdownButtonFormField<int>(
              value: _selectedCatId,
              dropdownColor: AppColors.darkCard,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Danh mục lưu sản phẩm', labelStyle: TextStyle(color: Colors.white54), border: InputBorder.none),
              items: [
                const DropdownMenuItem(value: null, child: Text('-- Chọn danh mục --', style: TextStyle(color: Colors.white54))),
                ..._categories.map((c) => DropdownMenuItem(value: c['category_id'] as int, child: Text(c['name'] ?? ''))),
              ],
              onChanged: (v) => setState(() => _selectedCatId = v),
            ),
          ),

        const SizedBox(height: 24),
        const Text('Chọn linh kiện', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),

        // Slots
        ..._slots.keys.map((slot) {
          final sel = _slots[slot];
          return GestureDetector(
            onTap: () => _pickProduct(slot),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkCard, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel != null ? AppColors.staff.withOpacity(0.4) : Colors.white12),
              ),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.staff.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text(slot[0], style: const TextStyle(color: AppColors.staff, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(slot, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                  Text(sel != null ? sel['name'] ?? '' : 'Chưa chọn',
                    style: TextStyle(color: sel != null ? Colors.white : Colors.white38, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                if (sel != null) ...[
                  Text('${_fmt(double.tryParse(sel['price'].toString()) ?? 0)}đ', style: const TextStyle(color: AppColors.success, fontSize: 12)),
                  const SizedBox(width: 4),
                  GestureDetector(onTap: () => setState(() => _slots[slot] = null), child: const Icon(Icons.close, color: Colors.white38, size: 18)),
                ] else
                  const Icon(Icons.add_circle_outline, color: AppColors.staff, size: 20),
              ]),
            ),
          );
        }),

        const SizedBox(height: 12),

        // Total
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.staff.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.staff.withOpacity(0.2)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Tổng giá trị', style: TextStyle(color: Colors.white70)),
            Text('${_fmt(_total)}đ', style: const TextStyle(color: AppColors.staff, fontWeight: FontWeight.bold, fontSize: 20)),
          ]),
        ),
        const SizedBox(height: 20),

        // Submit
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_outlined, size: 18),
            label: const Text('Đăng bán cấu hình PC này'),
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.staff, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  const _Field({required this.controller, required this.label, this.maxLines = 1});
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller, maxLines: maxLines,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label, labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      filled: true, fillColor: AppColors.darkCard,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    ),
  );
}

// ─── Build Detail Modal ───────────────────────────────────────────────────────

class _BuildDetailModal extends StatelessWidget {
  final dynamic pcBuild;
  const _BuildDetailModal({required this.pcBuild});

  @override
  Widget build(BuildContext context) {
    final items = pcBuild['items'] as List<dynamic>? ?? [];
    final total = double.tryParse(pcBuild['total_price']?.toString() ?? '0') ?? 0;
    return DraggableScrollableSheet(
      initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.4, expand: false,
      builder: (_, ctrl) => Column(children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
            Text(pcBuild['build_name'] ?? 'Chi tiết Build', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            if (total > 0) Text('${_fmt(total)}đ', style: const TextStyle(color: AppColors.success, fontSize: 15)),
          ]),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Chưa có linh kiện', style: TextStyle(color: Colors.white54)))
              : ListView.separated(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: AppColors.darkCardAlt, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.memory_outlined, color: Colors.white38),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item['product_name'] ?? '—', style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('SL: ${item['quantity']}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                        ])),
                        Text('${_fmt(double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0)}đ', style: const TextStyle(color: AppColors.success, fontSize: 13)),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

// ─── Product Picker Sheet ─────────────────────────────────────────────────────

class _ProductPickerSheet extends StatefulWidget {
  final String slot;
  final List<dynamic> products;
  final Map<String, dynamic>? selected;
  final Function(Map<String, dynamic>) onSelect;
  const _ProductPickerSheet({required this.slot, required this.products, required this.selected, required this.onSelect});
  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _search = '';
  List<dynamic> get _filtered => widget.products.where((p) => _search.isEmpty || (p['name'] ?? '').toLowerCase().contains(_search.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.65,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16,16,8,8),
          child: Row(children: [
            Expanded(child: Text('Chọn ${widget.slot}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
            IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16,0,16,8),
          child: TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tìm sản phẩm...', hintStyle: TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              filled: true, fillColor: AppColors.darkCard,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filtered.length,
          separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
          itemBuilder: (_, i) {
            final p = _filtered[i];
            final isSel = widget.selected?['product_id'] == p['product_id'];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: p['image_url'] != null
                    ? Image.network(p['image_url'], width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              title: Text(p['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('${_fmt(double.tryParse(p['price'].toString()) ?? 0)}đ', style: const TextStyle(color: AppColors.success, fontSize: 12)),
              trailing: isSel ? const Icon(Icons.check_circle, color: AppColors.staff) : null,
              onTap: () => widget.onSelect(p as Map<String, dynamic>),
            );
          },
        )),
      ]),
    );
  }

  Widget _placeholder() => Container(width: 48, height: 48, color: AppColors.darkCardAlt, child: const Icon(Icons.memory_outlined, color: Colors.white24, size: 24));
  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');}

