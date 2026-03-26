class PromotionModel {
  final int promotionId;
  final String code;
  final double discountPercent;
  final DateTime? validFrom;
  final DateTime? validTo;

  PromotionModel({
    required this.promotionId,
    required this.code,
    required this.discountPercent,
    this.validFrom,
    this.validTo,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) => PromotionModel(
        promotionId: json['promotion_id'] ?? 0,
        code: json['code'] ?? '',
        discountPercent: double.tryParse(json['discount_percent'].toString()) ?? 0.0,
        validFrom: json['valid_from'] != null
            ? DateTime.tryParse(json['valid_from'].toString())
            : null,
        validTo: json['valid_to'] != null
            ? DateTime.tryParse(json['valid_to'].toString())
            : null,
      );

  String get statusLabel {
    final now = DateTime.now();
    if (validFrom != null && now.isBefore(validFrom!)) return 'Sắp diễn ra';
    if (validTo != null && now.isAfter(validTo!)) return 'Hết hạn';
    return 'Đang chạy';
  }
}
