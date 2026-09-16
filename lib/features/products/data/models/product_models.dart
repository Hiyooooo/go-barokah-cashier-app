class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.cost,
    required this.stock,
    required this.isActive,
    required this.discountAmount,
    required this.finalPrice,
    this.categoryId,
    this.typeId,
    this.description,
    this.imageUrl,
    this.criticalStock,
    this.minOrderQuantity,
    this.category,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final int? categoryId;
  final int? typeId;
  final num price;
  final num? cost;
  final num? finalPrice;
  final num? discountAmount;
  final String? description;
  final String? imageUrl;
  final int stock;
  final bool isActive;
  final int? criticalStock;
  final int? minOrderQuantity;
  final ProductCategory? category;
  final ProductCategory? type;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    categoryId: (json['categoryId'] as num?)?.toInt(),
    typeId: (json['typeId'] as num?)?.toInt(),
    price: json['price'] as num,
    cost: json['cost'] as num?,
    finalPrice: json['final_price'] as num?,
    discountAmount: json['discount_amount'] as num?,
    description: json['description'] as String?,
    imageUrl: json['image_url'] as String?,
    stock: (json['stock'] as num).toInt(),
    isActive: json['is_active'] as bool,
    criticalStock: (json['critical_stock'] as num?)?.toInt(),
    minOrderQuantity: (json['min_order_quantity'] as num?)?.toInt(),
    category: _category(json['category']),
    type: _category(json['type']),
    createdAt: _dateTime(json['created_at']),
    updatedAt: _dateTime(json['updated_at']),
  );
}

class ProductCategory {
  const ProductCategory({required this.id, required this.name});

  final int id;
  final String name;

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      ProductCategory(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
      );
}

class ProductPage {
  const ProductPage({required this.items, this.meta});

  final List<Product> items;
  final PaginationMeta? meta;

  factory ProductPage.fromJson(Map<String, dynamic> json) => ProductPage(
    items: (json['data'] as List<dynamic>? ?? const [])
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList(),
    meta: _pagination(json['meta']),
  );
}

class PaginationMeta {
  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) => PaginationMeta(
    page: (json['page'] as num).toInt(),
    limit: (json['limit'] as num).toInt(),
    total: (json['total'] as num).toInt(),
    totalPages: (json['totalPages'] as num).toInt(),
  );
}

List<ProductCategory>? _categoryList(Object? value) => value is List
    ? value
          .whereType<Map<String, dynamic>>()
          .map(ProductCategory.fromJson)
          .toList()
    : null;

ProductCategory? _category(Object? value) =>
    value is Map<String, dynamic> ? ProductCategory.fromJson(value) : null;

PaginationMeta? _pagination(Object? value) =>
    value is Map<String, dynamic> ? PaginationMeta.fromJson(value) : null;

DateTime? _dateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

List<ProductCategory> parseCategories(Map<String, dynamic> json) =>
    _categoryList(json['data']) ?? const [];
