class CartItemModel {
  final int cartItemId;
  final int cartId;
  final int? productId;
  final int? userBuildId;
  final int quantity;
  final String? productName;
  final double? productPrice;
  final String? imageUrl;
  final int? stockQuantity;
  final String? buildName;
  final double? buildPrice;

  CartItemModel({
    required this.cartItemId,
    required this.cartId,
    this.productId,
    this.userBuildId,
    required this.quantity,
    this.productName,
    this.productPrice,
    this.imageUrl,
    this.stockQuantity,
    this.buildName,
    this.buildPrice,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
        cartItemId: json['cart_item_id'] ?? 0,
        cartId: json['cart_id'] ?? 0,
        productId: json['product_id'],
        userBuildId: json['user_build_id'],
        quantity: json['quantity'] ?? 1,
        productName: json['product_name'],
        productPrice: json['product_price'] != null
            ? double.tryParse(json['product_price'].toString())
            : null,
        imageUrl: json['image_url'],
        stockQuantity: json['stock_quantity'],
        buildName: json['build_name'],
        buildPrice: json['build_price'] != null
            ? double.tryParse(json['build_price'].toString())
            : null,
      );

  String get displayName => productName ?? buildName ?? 'Sản phẩm';
  double get unitPrice => productPrice ?? buildPrice ?? 0.0;
  double get subtotal => unitPrice * quantity;
}
