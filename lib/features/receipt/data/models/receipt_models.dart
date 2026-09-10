class Receipt {
  const Receipt({
    required this.saleNumber,
    required this.createdAt,
    required this.cashierName,
    required this.paymentMethod,
    required this.items,
    required this.subtotal,
    required this.discountTotal,
    required this.grandTotal,
    required this.cashReceived,
    required this.changeAmount,
    this.notes,
  });

  final String saleNumber;
  final DateTime? createdAt;
  final String cashierName;
  final String paymentMethod;
  final List<ReceiptItem> items;
  final num subtotal;
  final num discountTotal;
  final num grandTotal;
  final num cashReceived;
  final num changeAmount;
  final String? notes;

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
    saleNumber: _string(json, 'sale_number', 'saleNumber'),
    createdAt: _dateTime(json['transaction_date'] ?? json['transactionDate']),
    cashierName: _cashierName(json),
    paymentMethod: _string(json, 'payment_method', 'paymentMethod'),
    items: _items(json['items']),
    subtotal: _number(json, 'subtotal', 'subtotal'),
    discountTotal:
        (json['discount_total'] ??
                json['total_discount'] ??
                json['discountTotal'])
            as num,
    grandTotal: (json['grand_total'] ?? json['grandTotal']) as num,
    cashReceived: (json['cash_received'] ?? json['cashReceived']) as num,
    changeAmount: (json['change_amount'] ?? json['changeAmount']) as num,
    notes: json['notes'] as String?,
  );

  factory Receipt.fromCashSaleJson(Map<String, dynamic> json) =>
      Receipt.fromJson(json);
}

class ReceiptItem {
  const ReceiptItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.discountAmount,
    required this.finalUnitPrice,
    required this.subtotal,
    this.productId,
  });

  final int? productId;
  final String productName;
  final int quantity;
  final num unitPrice;
  final num discountAmount;
  final num finalUnitPrice;
  final num subtotal;

  factory ReceiptItem.fromJson(Map<String, dynamic> json) => ReceiptItem(
    productId: ((json['product_id'] ?? json['productId']) as num?)?.toInt(),
    productName: _string(json, 'product_name', 'productName'),
    quantity: (json['quantity'] as num).toInt(),
    unitPrice: (json['unit_price'] ?? json['unitPrice']) as num,
    discountAmount: (json['discount'] ?? json['discountAmount'] ?? 0) as num,
    finalUnitPrice: (json['final_unit_price'] ?? json['finalUnitPrice']) as num,
    subtotal: json['subtotal'] as num,
  );
}

DateTime? _dateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

String _string(Map<String, dynamic> json, String snake, String camel) =>
    (json[snake] ?? json[camel]) as String;

num _number(Map<String, dynamic> json, String snake, String camel) =>
    (json[snake] ?? json[camel]) as num;

List<ReceiptItem> _items(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => ReceiptItem.fromJson(item.cast<String, dynamic>()))
      .toList();
}

String _cashierName(Map<String, dynamic> json) {
  final cashier = json['cashier'];
  if (cashier is Map) {
    final name = cashier['name'];
    if (name is String) return name;
  }
  return (json['cashierName'] as String?) ?? '';
}
