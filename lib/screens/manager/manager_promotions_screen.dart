import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/promotion_model.dart';
import '../../services/api_service.dart';
import '../../widgets/role_scaffold.dart';

class ManagerPromotionsScreen extends StatefulWidget {
  const ManagerPromotionsScreen({super.key});

  @override
  State<ManagerPromotionsScreen> createState() => _ManagerPromotionsScreenState();
}

class _ManagerPromotionsScreenState extends State<ManagerPromotionsScreen> {
  final _api = ApiService();
  List<PromotionModel> _promos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/promotions');
      final data = res.data;
      final list = data is List ? data : data['data'] ?? [];
      _promos = list.map<PromotionModel>((e) => PromotionModel.fromJson(e)).toList();
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _showModal([PromotionModel? promo]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PromoModal(promo: promo, onSaved: _load),
    );
  }

  Future<void> _delete(PromotionModel promo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: Text('Xóa mã "${promo.code}"?',
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
      await _api.delete('/promotions/${promo.promotionId}');
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error));
    }
  }

  Color _statusColor(String s) {
    if (s == 'Sắp diễn ra') return AppColors.info;
    if (s == 'Đang chạy') return AppColors.success;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return RoleScaffold(
      title: 'Quản lý khuyến mãi',
      accentColor: AppColors.manager,
      currentRoute: '/manager/promotions',
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
              child: _promos.isEmpty
                  ? const Center(
                      child: Text('Chưa có khuyến mãi',
                          style: TextStyle(color: Colors.white54)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 380,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: _promos.length,
                      itemBuilder: (_, i) {
                        final p = _promos[i];
                        final status = p.statusLabel;
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.manager.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(p.code,
                                        style: const TextStyle(
                                            color: AppColors.manager,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(status,
                                        style: TextStyle(
                                            color: _statusColor(status),
                                            fontSize: 11)),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text('-${p.discountPercent.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold)),
                              const Spacer(),
                              if (p.validFrom != null)
                                Text(
                                  'Từ: ${_fmtDate(p.validFrom!)}',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 11),
                                ),
                              if (p.validTo != null)
                                Text(
                                  'Đến: ${_fmtDate(p.validTo!)}',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 11),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                      onTap: () => _showModal(p),
                                      child: const Icon(Icons.edit_outlined,
                                          color: AppColors.manager, size: 18)),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                      onTap: () => _delete(p),
                                      child: const Icon(Icons.delete_outline,
                                          color: AppColors.error, size: 18)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _PromoModal extends StatefulWidget {
  final PromotionModel? promo;
  final VoidCallback onSaved;
  const _PromoModal({this.promo, required this.onSaved});

  @override
  State<_PromoModal> createState() => _PromoModalState();
}

class _PromoModalState extends State<_PromoModal> {
  final _api = ApiService();
  final _codeCtrl = TextEditingController();
  final _discCtrl = TextEditingController();
  DateTime? _from;
  DateTime? _to;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.promo != null) {
      _codeCtrl.text = widget.promo!.code;
      _discCtrl.text = widget.promo!.discountPercent.toString();
      _from = widget.promo!.validFrom;
      _to = widget.promo!.validTo;
    }
  }

  Future<void> _pickDate(bool isFrom) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark(),
        child: child!,
      ),
    );
    if (d != null) setState(() => isFrom ? _from = d : _to = d);
  }

  Future<void> _save() async {
    if (_codeCtrl.text.isEmpty || _discCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    final data = {
      'code': _codeCtrl.text.toUpperCase(),
      'discount_percent': double.tryParse(_discCtrl.text) ?? 0,
      if (_from != null) 'valid_from': _from!.toIso8601String(),
      if (_to != null) 'valid_to': _to!.toIso8601String(),
    };
    try {
      if (widget.promo == null) {
        await _api.post('/promotions', data: data);
      } else {
        await _api.put('/promotions/${widget.promo!.promotionId}', data: data);
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

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.promo == null ? 'Thêm khuyến mãi' : 'Sửa khuyến mãi',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 20),
          TextField(
            controller: _codeCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _deco('Mã khuyến mãi *'),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _discCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: _deco('Giảm giá (%) *'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickDate(true),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _from != null ? 'Từ: ${_fmtDate(_from!)}' : 'Ngày bắt đầu',
                      style: TextStyle(
                          color: _from != null ? Colors.white : Colors.white38),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickDate(false),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.darkCardAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _to != null ? 'Đến: ${_fmtDate(_to!)}' : 'Ngày kết thúc',
                      style: TextStyle(
                          color: _to != null ? Colors.white : Colors.white38),
                    ),
                  ),
                ),
              ),
            ],
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
                    : const Text('Lưu',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
