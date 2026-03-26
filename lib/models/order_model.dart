class OrderModel {
  final int orderId;
  final int userId;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final DateTime orderDate;
  final String status;
  final double totalAmount;
  final String? shippingAddress;
  final String? paymentType;
  final String? promotionCode;
  final String? paymentMethod;
  final List<OrderDetailModel> details;

  OrderModel({
    required this.orderId,
    required this.userId,
    this.userName,
    this.userEmail,
    this.userPhone,
    required this.orderDate,
    required this.status,
    required this.totalAmount,
    this.shippingAddress,
    this.paymentType,
    this.promotionCode,
    this.paymentMethod,
    this.details = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        orderId: json['order_id'] ?? 0,
        userId: json['user_id'] ?? 0,
        userName: json['user_name'],
        userEmail: json['user_email'],
        userPhone: json['user_phone'],
        orderDate: DateTime.tryParse(json['order_date']?.toString() ?? '') ?? DateTime.now(),
        status: json['status'] ?? 'Pending',
        totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
        shippingAddress: json['shipping_address'],
        paymentType: json['payment_type'],
        promotionCode: json['promotion_code'],
        paymentMethod: json['payment_method'],
        details: (json['details'] as List<dynamic>? ?? [])
            .map((d) => OrderDetailModel.fromJson(d))
            .toList(),
      );
}

class OrderDetailModel {
  final int orderDetailId;
  final int orderId;
  final int? productId;
  final int? userBuildId;
  final int quantity;
  final double price;
  final String? productName;
  final String? imageUrl;

  OrderDetailModel({
    required this.orderDetailId,
    required this.orderId,
    this.productId,
    this.userBuildId,
    required this.quantity,
    required this.price,
    this.productName,
    this.imageUrl,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) => OrderDetailModel(
        orderDetailId: json['order_detail_id'] ?? 0,
        orderId: json['order_id'] ?? 0,
        productId: json['product_id'],
        userBuildId: json['user_build_id'],
        quantity: json['quantity'] ?? 1,
        price: double.tryParse(json['price'].toString()) ?? 0.0,
        productName: json['product_name'],
        imageUrl: json['image_url'],
      );
}
