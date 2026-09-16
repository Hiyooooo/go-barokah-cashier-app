class Cart {
  const Cart({required this.items, required this.summary});

  final List<CartItem> items;
  final CartSummary summary;

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
    items: (json['items'] as List<dynamic>? ?? const [])
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList(),
    summary: CartSummary.fromJson(json['summary'] as Map<String, dynamic>),
  );
}

class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.finalPrice,
    required this.quantity,
    required this.subtotal,
    required this.stock,
    this.imageUrl,
    this.discountAmount,
    this.normalSubtotal,
    this.discountSubtotal,
  });

  final int id;
  final int productId;
  final String name;
  final String? imageUrl;
  final num price;
  final num? discountAmount;
  final num finalPrice;
  final int quantity;
  final num? normalSubtotal;
  final num? discountSubtotal;
  final num subtotal;
  final int stock;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: (json['id'] as num).toInt(),
    productId: (json['product_id'] as num).toInt(),
    name: json['name'] as String,
    imageUrl: json['image_url'] as String?,
    price: json['price'] as num,
    discountAmount: json['discount_amount'] as num?,
    finalPrice: json['final_price'] as num,
    quantity: (json['quantity'] as num).toInt(),
    normalSubtotal: json['normal_subtotal'] as num?,
    discountSubtotal: json['discount_subtotal'] as num?,
    subtotal: json['subtotal'] as num,
    stock: (json['stock'] as num).toInt(),
  );
}

class CartSummary {
  const CartSummary({
    required this.itemsCount,
    required this.totalQuantity,
    required this.normalSubtotal,
    required this.discountTotal,
    required this.subtotal,
  });

  final int itemsCount;
  final int totalQuantity;
  final num normalSubtotal;
  final num discountTotal;
  final num subtotal;

  factory CartSummary.fromJson(Map<String, dynamic> json) => CartSummary(
    itemsCount: (json['items_count'] as num).toInt(),
    totalQuantity: (json['total_quantity'] as num).toInt(),
    normalSubtotal: json['normal_subtotal'] as num,
    discountTotal: json['discount_total'] as num,
    subtotal: json['subtotal'] as num,
  );
}
