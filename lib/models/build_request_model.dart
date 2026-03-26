class BuildRequestModel {
  final int requestId;
  final int userId;
  final int? staffId;
  final String? customerNote;
  final double? budgetRange;
  final String status;
  final int? userBuildId;
  final DateTime? createdAt;
  final String? customerName;
  final String? customerEmail;
  final String? staffName;
  final String? buildName;
  final double? totalPrice;

  BuildRequestModel({
    required this.requestId,
    required this.userId,
    this.staffId,
    this.customerNote,
    this.budgetRange,
    required this.status,
    this.userBuildId,
    this.createdAt,
    this.customerName,
    this.customerEmail,
    this.staffName,
    this.buildName,
    this.totalPrice,
  });

  factory BuildRequestModel.fromJson(Map<String, dynamic> json) =>
      BuildRequestModel(
        requestId: json['request_id'] ?? 0,
        userId: json['user_id'] ?? 0,
        staffId: json['staff_id'],
        customerNote: json['customer_note'],
        budgetRange: json['budget_range'] != null
            ? double.tryParse(json['budget_range'].toString())
            : null,
        status: json['status'] ?? 'pending',
        userBuildId: json['user_build_id'],
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        customerName: json['customer_name'],
        customerEmail: json['customer_email'],
        staffName: json['staff_name'],
        buildName: json['build_name'],
        totalPrice: json['total_price'] != null
            ? double.tryParse(json['total_price'].toString())
            : null,
      );
}
