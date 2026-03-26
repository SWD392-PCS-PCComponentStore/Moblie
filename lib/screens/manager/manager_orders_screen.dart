import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../../widgets/role_scaffold.dart';

class ManagerOrdersScreen extends StatefulWidget {
  const ManagerOrdersScreen({super.key});

  @override
  State<ManagerOrdersScreen> createState() => _ManagerOrdersScreenState();
}

class _ManagerOrdersScreenState extends State<ManagerOrdersScreen> {
  final _api = ApiService();
  List<OrderModel> _orders = [];
  List<OrderModel> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _statusFilter = 'Tất cả';

  final _statuses = ['Tất cả', 'Pending', 'Processing', 'Shipped', 'Delivered', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/orders');
      final data = res.data;
      final list = data is List ? data : data['data'] ?? [];
      _orders = list.map<OrderModel>((e) => OrderModel.fromJson(e)).toList();
    } catch (_) {}
    _applyFilter();
    setState(() => _loading = false);
  }

  void _applyFilter() {
    _filtered = _orders.where((o) {
      final matchSearch = _search.isEmpty ||
          o.orderId.toString().contains(_search) ||
          (o.userName ?? '').toLowerCase().contains(_search.toLowerCase()) ||
          (o.userEmail ?? '').toLowerCase().contains(_search.toLowerCase());
      final matchStatus = _statusFilter == 'Tất cả' ||
          o.status.toLowerCase() == _statusFilter.toLowerCase();
      return matchSearch && matchStatus;
    }).toList();
  }

  double get _totalRevenue => _orders
      .where((o) => o.status.toLowerCase() == 'completed')
      .fold(0, (sum, o) => sum + o.totalAmount);

  int get _pendingCount =>
      _orders.where((o) => o.status.toLowerCase() == 'pending').length;
  int get _completedCount =>
      _orders.where((o) => o.status.toLowerCase() == 'completed').length;

  void _showDetail(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _OrderDetailModal(order: order, onUpdated: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleScaffold(
      title: 'Quản lý đơn hàng',
      accentColor: AppColors.manager,
      currentRoute: '/manager/orders',
      navItems: managerNavItems,
      body: Column(
        children: [
          // Stat row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _MiniStat('Tổng đơn', _orders.length.toString(), AppColors.manager),
                const SizedBox(width: 8),
                _MiniStat('Chờ xử lý', _pendingCount.toString(), AppColors.warning),
                const SizedBox(width: 8),
                _MiniStat('Hoàn thành', _completedCount.toString(), AppColors.success),
                const SizedBox(width: 8),
                _MiniStat('Doanh thu', '${_fmtM(_totalRevenue)}đ', AppColors.info),
              ],
            ),
          ),

          // Search + filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tìm theo ID, tên, email...',
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
          const SizedBox(height: 12),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.manager))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const Center(
                            child: Text('Không tìm thấy đơn hàng',
                                style: TextStyle(color: Colors.white54)))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final o = _filtered[i];
                              return GestureDetector(
                                onTap: () => _showDetail(o),
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
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('#${o.orderId}',
                                              style: const TextStyle(
                                                  color: AppColors.admin,
                                                  fontWeight: FontWeight.bold)),
                                          _StatusBadge(o.status),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(o.userName ?? 'Khách hàng',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500)),
                                      Text(o.userEmail ?? '',
                                          style: TextStyle(
                                              color: Colors.white.withOpacity(0.5),
                                              fontSize: 12)),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(_fmtDate(o.orderDate),
                                              style: TextStyle(
                                                  color: Colors.white.withOpacity(0.5),
                                                  fontSize: 12)),
                                          Text('${_fmt(o.totalAmount)}đ',
                                              style: const TextStyle(
                                                  color: AppColors.success,
                                                  fontWeight: FontWeight.bold)),
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

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  String _fmtM(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return _fmt(v);
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(label,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.orderStatusColor(status).withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(status,
            style: TextStyle(
                color: AppColors.orderStatusColor(status), fontSize: 12)),
      );
}

class _OrderDetailModal extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onUpdated;
  const _OrderDetailModal({required this.order, required this.onUpdated});

  @override
  State<_OrderDetailModal> createState() => _OrderDetailModalState();
}

class _OrderDetailModalState extends State<_OrderDetailModal> {
  final _api = ApiService();
  late String _status;
  final _addrCtrl = TextEditingController();
  bool _loading = false;

  final _statuses = ['Pending', 'Processing', 'Shipped', 'Delivered', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _status = widget.order.status;
    _addrCtrl.text = widget.order.shippingAddress ?? '';
  }

  Future<void> _update() async {
    setState(() => _loading = true);
    try {
      await _api.put('/orders/${widget.order.orderId}', data: {
        'status': _status,
        'shipping_address': _addrCtrl.text,
      });
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
    final o = widget.order;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
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
                Text('Đơn hàng #${o.orderId}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                _StatusBadge(o.status),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow('Khách hàng', o.userName ?? '—'),
            _InfoRow('Email', o.userEmail ?? '—'),
            _InfoRow('SĐT', o.userPhone ?? '—'),
            _InfoRow('Tổng tiền', '${o.totalAmount.toStringAsFixed(0)}đ'),
            _InfoRow('Thanh toán', o.paymentMethod ?? '—'),
            const Divider(color: Colors.white12, height: 24),

            // Update status
            const Text('Cập nhật trạng thái',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _status,
              dropdownColor: AppColors.darkCardAlt,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.darkCardAlt,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              items: _statuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addrCtrl,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Địa chỉ giao hàng',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                filled: true,
                fillColor: AppColors.darkCardAlt,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _update,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.manager,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Lưu thay đổi',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
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
              width: 100,
              child: Text(label,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      );
}
