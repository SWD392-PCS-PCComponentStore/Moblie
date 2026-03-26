import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/build_request_model.dart';
import '../../services/api_service.dart';
import '../../widgets/role_scaffold.dart';

class StaffRequestsScreen extends StatefulWidget {
  const StaffRequestsScreen({super.key});

  @override
  State<StaffRequestsScreen> createState() => _StaffRequestsScreenState();
}

class _StaffRequestsScreenState extends State<StaffRequestsScreen> {
  final _api = ApiService();
  List<BuildRequestModel> _requests = [];
  List<BuildRequestModel> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _statusFilter = 'Tất cả';

  final _statuses = [
    'Tất cả','pending','assigned','in_progress','completed','cancelled','rejected'
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/staff-build-requests');
      final data = res.data;
      final list = data is List ? data : data['data'] ?? [];
      _requests = list.map<BuildRequestModel>((e) => BuildRequestModel.fromJson(e)).toList();
    } catch (_) {}
    _applyFilter();
    setState(() => _loading = false);
  }

  void _applyFilter() {
    _filtered = _requests.where((r) {
      final matchSearch = _search.isEmpty ||
          '#${r.requestId}'.contains(_search) ||
          (r.customerName ?? '').toLowerCase().contains(_search.toLowerCase());
      final matchStatus = _statusFilter == 'Tất cả' || r.status == _statusFilter;
      return matchSearch && matchStatus;
    }).toList();
  }

  void _showDetail(BuildRequestModel r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RequestDetailModal(request: r, onUpdated: _load, api: _api),
    );
  }

  String _statusLabel(String s) => const {
    'pending':'Chờ duyệt','assigned':'Đã phân công','in_progress':'Đang xử lý',
    'completed':'Hoàn thành','cancelled':'Đã hủy','rejected':'Từ chối',
  }[s] ?? s;

  @override
  Widget build(BuildContext context) {
    return RoleScaffold(
      title: 'Build Requests',
      accentColor: AppColors.staff,
      currentRoute: '/staff/requests',
      navItems: staffNavItems,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16,16,16,8),
            child: Row(children: [
              Expanded(child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, mã...',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38),
                  filled: true, fillColor: AppColors.darkCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (v) { _search = v; _applyFilter(); setState(() {}); },
              )),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(10)),
                child: DropdownButton<String>(
                  value: _statusFilter,
                  dropdownColor: AppColors.darkCard,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  underline: const SizedBox(),
                  items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(_statusLabel(s)))).toList(),
                  onChanged: (v) { _statusFilter = v!; _applyFilter(); setState(() {}); },
                ),
              ),
            ]),
          ),
          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _MiniStat('Tổng', _requests.length, AppColors.staff),
              const SizedBox(width: 8),
              _MiniStat('Chờ', _requests.where((r) => r.status=='pending').length, AppColors.warning),
              const SizedBox(width: 8),
              _MiniStat('Xử lý', _requests.where((r) => r.status=='in_progress').length, AppColors.admin),
              const SizedBox(width: 8),
              _MiniStat('Xong', _requests.where((r) => r.status=='completed').length, AppColors.success),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.staff))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.inbox_outlined, color: Colors.white24, size: 56),
                            SizedBox(height: 12),
                            Text('Không tìm thấy request', style: TextStyle(color: Colors.white54)),
                          ]))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final r = _filtered[i];
                              return GestureDetector(
                                onTap: () => _showDetail(r),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.buildRequestStatusColor(r.status).withOpacity(0.2)),
                                  ),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                      Text('#${r.requestId}', style: const TextStyle(color: AppColors.staff, fontWeight: FontWeight.bold)),
                                      _StatusBadge(r.status),
                                    ]),
                                    const SizedBox(height: 6),
                                    Text(r.customerName ?? 'Khách hàng', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                    Text(r.customerEmail ?? '', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                                    const SizedBox(height: 6),
                                    Row(children: [
                                      const Icon(Icons.attach_money, color: AppColors.success, size: 14),
                                      Text(
                                        r.budgetRange != null ? '${_fmt(r.budgetRange!)}đ' : 'Không giới hạn',
                                        style: const TextStyle(color: AppColors.success, fontSize: 12),
                                      ),
                                      const Spacer(),
                                      if (r.createdAt != null)
                                        Text(_fmtDate(r.createdAt!), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                                    ]),
                                    if (r.customerNote != null && r.customerNote!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(r.customerNote!, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ]),
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

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
}

class _MiniStat extends StatelessWidget {
  final String label; final int value; final Color color;
  const _MiniStat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Text(value.toString(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ]),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);
  String get _label => const {'pending':'Chờ duyệt','assigned':'Đã phân công','in_progress':'Đang xử lý','completed':'Hoàn thành','cancelled':'Đã hủy','rejected':'Từ chối'}[status] ?? status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: AppColors.buildRequestStatusColor(status).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
    child: Text(_label, style: TextStyle(color: AppColors.buildRequestStatusColor(status), fontSize: 11, fontWeight: FontWeight.w500)),
  );
}

class _RequestDetailModal extends StatefulWidget {
  final BuildRequestModel request;
  final VoidCallback onUpdated;
  final ApiService api;
  const _RequestDetailModal({required this.request, required this.onUpdated, required this.api});
  @override
  State<_RequestDetailModal> createState() => _RequestDetailModalState();
}

class _RequestDetailModalState extends State<_RequestDetailModal> {
  bool _loading = false;
  final _rejectCtrl = TextEditingController();
  bool _showReject = false;
  bool _showBuildPanel = false;
  List<dynamic> _products = [];
  bool _productsLoading = false;
  String _buildName = '';

  final Map<String, Map<String, dynamic>?> _slots = {
    'CPU': null, 'GPU': null, 'RAM': null, 'Storage': null,
    'Mainboard': null, 'PSU': null, 'Case': null, 'Cooling': null,
  };

  @override
  void initState() {
    super.initState();
    if (widget.request.status == 'in_progress' || widget.request.status == 'assigned') {
      _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _productsLoading = true);
    try {
      final res = await widget.api.get('/products');
      final data = res.data;
      _products = data is List ? data : data['data'] ?? [];
    } catch (_) {}
    setState(() => _productsLoading = false);
  }

  Future<void> _approve() async {
    setState(() => _loading = true);
    try {
      await widget.api.patch('/staff-build-requests/${widget.request.requestId}/assign', data: {'status': 'in_progress'});
      if (mounted) Navigator.pop(context);
      widget.onUpdated();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error));
    }
    setState(() => _loading = false);
  }

  Future<void> _reject() async {
    if (_rejectCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập lý do'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.api.put('/staff-build-requests/${widget.request.requestId}', data: {'status': 'rejected', 'customer_note': _rejectCtrl.text.trim()});
      if (mounted) Navigator.pop(context);
      widget.onUpdated();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error));
    }
    setState(() => _loading = false);
  }

  Future<void> _submitBuild() async {
    final items = _slots.entries.where((e) => e.value != null).toList();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ít nhất 1 linh kiện'), backgroundColor: AppColors.error));
      return;
    }
    if (_buildName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên cấu hình'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.api.post('/staff-build-requests/${widget.request.requestId}/submit-build', data: {
        'build_name': _buildName.trim(),
        'user_id': widget.request.userId,
        'items': items.map((e) => {'product_id': e.value!['product_id'], 'quantity': 1}).toList(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã gửi cấu hình cho khách!'), backgroundColor: AppColors.success));
      }
      widget.onUpdated();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error));
    }
    setState(() => _loading = false);
  }

  double get _total => _slots.values.where((v) => v != null).fold(0.0, (sum, v) => sum + (double.tryParse(v!['price'].toString()) ?? 0));

  List<dynamic> _slotProducts(String slot) {
    final keys = const {
      'CPU': ['cpu','processor','vi xử lý'], 'GPU': ['gpu','vga','graphic','card màn'],
      'RAM': ['ram','memory','bộ nhớ'], 'Storage': ['ssd','hdd','storage','ổ cứng','nvme'],
      'Mainboard': ['mainboard','motherboard','bo mạch'], 'PSU': ['psu','nguồn','power'],
      'Case': ['case','vỏ máy'], 'Cooling': ['cooling','tản nhiệt','cooler','fan'],
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
        slot: slot,
        products: _slotProducts(slot),
        selected: _slots[slot],
        onSelect: (p) { setState(() => _slots[slot] = p); Navigator.pop(context); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final budget = r.budgetRange;
    final overBudget = budget != null && _total > budget;

    return DraggableScrollableSheet(
      initialChildSize: 0.7, maxChildSize: 0.95, minChildSize: 0.4, expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Request #${r.requestId}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            _StatusBadge(r.status),
          ]),
          const SizedBox(height: 16),
          _InfoRow('Khách hàng', r.customerName ?? '—'),
          _InfoRow('Email', r.customerEmail ?? '—'),
          _InfoRow('Ngân sách', budget != null ? '${_fmt(budget)}đ' : 'Không giới hạn'),
          if (r.customerNote != null && r.customerNote!.isNotEmpty) _InfoRow('Ghi chú', r.customerNote!),
          if (r.staffName != null) _InfoRow('Nhân viên', r.staffName!),
          const Divider(color: Colors.white12, height: 28),

          // PENDING
          if (r.status == 'pending') ...[
            const Text('Hành động', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ElevatedButton.icon(
                icon: const Icon(Icons.check, size: 16), label: const Text('Duyệt & Xử lý'),
                onPressed: _loading ? null : _approve,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                icon: const Icon(Icons.close, size: 16), label: const Text('Từ chối'),
                onPressed: _loading ? null : () => setState(() => _showReject = !_showReject),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)),
              )),
            ]),
            if (_showReject) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _rejectCtrl, maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Lý do từ chối *', labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  filled: true, fillColor: AppColors.darkCardAlt,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: _loading ? null : _reject,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Xác nhận từ chối', style: TextStyle(color: Colors.white)),
              )),
            ],
          ],

          // IN PROGRESS / ASSIGNED → Build Panel
          if (r.status == 'in_progress' || r.status == 'assigned') ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Build Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              TextButton.icon(
                icon: Icon(_showBuildPanel ? Icons.expand_less : Icons.expand_more, color: AppColors.staff),
                label: Text(_showBuildPanel ? 'Thu gọn' : 'Mở', style: const TextStyle(color: AppColors.staff)),
                onPressed: () => setState(() => _showBuildPanel = !_showBuildPanel),
              ),
            ]),
            if (_showBuildPanel) ...[
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Tên cấu hình *', labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  filled: true, fillColor: AppColors.darkCardAlt,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                onChanged: (v) => _buildName = v,
              ),
              const SizedBox(height: 12),
              if (_productsLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.staff))
              else
                ..._slots.keys.map((slot) {
                  final sel = _slots[slot];
                  return GestureDetector(
                    onTap: () => _pickProduct(slot),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.darkCardAlt, borderRadius: BorderRadius.circular(10),
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
                          Text(sel != null ? sel['name'] ?? '' : 'Chưa chọn — nhấn để chọn',
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
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: overBudget ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: overBudget ? AppColors.error.withOpacity(0.3) : AppColors.success.withOpacity(0.3)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Tổng cấu hình', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                    Text('${_fmt(_total)}đ', style: TextStyle(color: overBudget ? AppColors.error : AppColors.success, fontWeight: FontWeight.bold, fontSize: 18)),
                  ]),
                  if (budget != null)
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('Ngân sách KH', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                      Text('${_fmt(budget)}đ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    ]),
                ]),
              ),
              if (overBudget)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_outlined, color: AppColors.error, size: 14),
                    const SizedBox(width: 4),
                    Text('Vượt ngân sách ${_fmt(_total - budget!)}đ', style: const TextStyle(color: AppColors.error, fontSize: 12)),
                  ]),
                ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_outlined, size: 18),
                label: const Text('Gửi cấu hình cho khách'),
                onPressed: _loading ? null : _submitBuild,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.staff, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )),
            ],
          ],

          // COMPLETED
          if (r.status == 'completed')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.success.withOpacity(0.3))),
              child: Row(children: [
                const Icon(Icons.check_circle_outline, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Đã gửi cấu hình cho khách', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                  if (r.buildName != null) Text(r.buildName!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ])),
              ]),
            ),

          // REJECTED
          if (r.status == 'rejected')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.error.withOpacity(0.3))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.cancel_outlined, color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(r.customerNote ?? 'Đã từ chối', style: const TextStyle(color: AppColors.error, fontSize: 13))),
              ]),
            ),

          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

class _InfoRow extends StatelessWidget {
  final String label; final String value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13))),
      Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13))),
    ]),
  );
}

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

  List<dynamic> get _filtered => widget.products.where((p) =>
    _search.isEmpty || (p['name'] ?? '').toLowerCase().contains(_search.toLowerCase())
  ).toList();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.65,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(children: [
            Expanded(child: Text('Chọn ${widget.slot}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
            IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tìm sản phẩm...',
              hintStyle: TextStyle(color: Colors.white38),
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
                    ? Image.network(p['image_url'], width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const _ImgPlaceholder())
                    : const _ImgPlaceholder(),
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

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
}

class _ImgPlaceholder extends StatelessWidget {
  const _ImgPlaceholder();
  @override
  Widget build(BuildContext context) => Container(width: 48, height: 48, color: AppColors.darkCardAlt, child: const Icon(Icons.memory_outlined, color: Colors.white24, size: 24));
}
