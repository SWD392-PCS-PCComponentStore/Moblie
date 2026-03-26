class CategoryModel {
  final int categoryId;
  final String name;
  final String? description;

  CategoryModel({
    required this.categoryId,
    required this.name,
    this.description,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        categoryId: json['category_id'] ?? 0,
        name: json['name'] ?? '',
        description: json['description'],
      );
}
