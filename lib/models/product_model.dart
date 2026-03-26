class ProductModel {
  final int productId;
  final String name;
  final String? description;
  final double price;
  final int stockQuantity;
  final String? imageUrl;
  final String status;
  final String? brand;
  final int categoryId;
  final String? categoryName;
  final String? createdAt;

  ProductModel({
    required this.productId,
    required this.name,
    this.description,
    required this.price,
    required this.stockQuantity,
    this.imageUrl,
    required this.status,
    this.brand,
    required this.categoryId,
    this.categoryName,
    this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        productId: json['product_id'] ?? 0,
        name: json['name'] ?? '',
        description: json['description'],
        price: double.tryParse(json['price'].toString()) ?? 0.0,
        stockQuantity: json['stock_quantity'] ?? 0,
        imageUrl: json['image_url'],
        status: json['status'] ?? 'Available',
        brand: json['brand'],
        categoryId: json['category_id'] ?? 0,
        categoryName: json['category_name'],
        createdAt: json['created_at'],
      );

  bool get isLowStock => stockQuantity < 10;
}
