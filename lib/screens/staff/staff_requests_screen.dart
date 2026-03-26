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

  final _statuses = ['Tất cả', 'pending', 'assigned', 'in_progress', 'completed', 'cancelled', 'rejected'];

  @override
  void initState() {
    super.initState();
    _load();
  }

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

  void _showDetail(BuildRequestModel request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RequestDetailModal(request: request, onUpdated: _load),
    );
  }

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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên, mã...',
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
                  value: _statusFilter,
                  dropdownColor: AppColors.darkCard,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  underline: const SizedBox(),
                  items: _statuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    _statusFilter = v!;
                    _applyFilter();
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.staff))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const Center(
                            child: Text('Không tìm thấy request',
                                style: TextStyle(color: Colors.white54)))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('#${r.requestId}',
                                              style: const TextStyle(
                                                  color: AppColors.staff,
                                                  fontWeight: FontWeight.bold)),
                                          _StatusBadge(r.status),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(r.customerName ?? 'Khách hàng',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500)),
                                      Text(r.customerEmail ?? '',
                                          style: TextStyle(
                                              color: Colors.white.withOpacity(0.5),
                                              fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.attach_money,
                                              color: AppColors.success, size: 14),
                                          Text(
                                            r.budgetRange != null
                                                ? '${_fmt(r.budgetRange!)}đ'
                                                : 'Không giới hạn',
                                            style: const TextStyle(
                                                color: AppColors.success,
                                                fontSize: 12),
                                          ),
                                          if (r.createdAt != null) ...[
                                            const SizedBox(width: 12),
                                            Text(
                                              _fmtDate(r.createdAt!),
                                              style: TextStyle(
                                                  color: Colors.white.withOpacity(0.4),
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ],
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
    );
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.buildRequestStatusColor(status).withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(status,
            style: TextStyle(
                color: AppColors.buildRequestStatusColor(status),
                fontSize: 11)),
      );
}

class _RequestDetailModal extends StatefulWidget {
  final BuildRequestModel request;
  final VoidCallback onUpdated;
  const _RequestDetailModal({required this.request, required this.onUpdated});

  @override
  State<_RequestDetailModal> createState() => _RequestDetailModalState();
}

class _RequestDetailModalState extends State<_RequestDetailModal> {
  final _api = ApiService();
  bool _loading = false;
  final _rejectCtrl = TextEditingController();
  bool _showReject = false;

  Future<void> _approve() async {
    setState(() => _loading = true);
    try {
      await _api.patch(
          '/staff-build-requests/${widget.request.requestId}/assign',
          data: {'status': 'in_progress'});
      if (mounted) Navigator.pop(context);
      widget.onUpdated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error));
    }
    setState(() => _loading = false);
  }

  Future<void> _reject() async {
    if (_rejectCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await _api.put('/staff-build-requests/${widget.request.requestId}',
          data: {'status': 'rejected', 'customer_note': _rejectCtrl.text});
      if (mounted) Navigator.pop(context);
      widget.onUpdated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Request #${r.requestId}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                _StatusBadge(r.status),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow('Khách hàng', r.customerName ?? '—'),
            _InfoRow('Email', r.customerEmail ?? '—'),
            _InfoRow('Ngân sách',
                r.budgetRange != null ? '${r.budgetRange!.toStringAsFixed(0)}đ' : '—'),
            if (r.customerNote != null && r.customerNote!.isNotEmpty)
              _InfoRow('Ghi chú', r.customerNote!),
            const Divider(color: Colors.white12, height: 24),

            // Actions
            if (r.status == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Duyệt'),
                      onPressed: _loading ? null : _approve,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Từ chối'),
                      onPressed: _loading
                          ? null
                          : () => setState(() => _showReject = !_showReject),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              if (_showReject) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _rejectCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Lý do từ chối *',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    filled: true,
                    fillColor: AppColors.darkCardAlt,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _reject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Xác nhận từ chối',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ],
            if (r.status == 'rejected') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel_outlined,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(r.customerNote ?? 'Đã từ chối',
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      );
}
