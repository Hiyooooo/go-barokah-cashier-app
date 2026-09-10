class CashSaleResult {
  const CashSaleResult({
    required this.status,
    required this.saleNumber,
    required this.transactionDate,
    required this.paymentMethod,
    required this.cashierName,
    required this.items,
    required this.subtotal,
    required this.discountTotal,
    required this.grandTotal,
    required this.cashReceived,
    required this.changeAmount,
    this.notes,
  });

  final String status;
  final String saleNumber;
  final DateTime? transactionDate;
  final String paymentMethod;
  final String cashierName;
  final List<CashSaleItem> items;
  final num subtotal;
  final num discountTotal;
  final num grandTotal;
  final num cashReceived;
  final num changeAmount;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'status': status,
    'sale_number': saleNumber,
    'transaction_date': transactionDate?.toIso8601String(),
    'payment_method': paymentMethod,
    'cashier': {'name': cashierName},
    'items': items.map((item) => item.toJson()).toList(),
    'subtotal': subtotal,
    'total_discount': discountTotal,
    'grand_total': grandTotal,
    'cash_received': cashReceived,
    'change_amount': changeAmount,
    'notes': notes,
  };

  factory CashSaleResult.fromJson(Map<String, dynamic> json) => CashSaleResult(
    status: (json['status'] ?? 'COMPLETED') as String,
    saleNumber: _string(json, 'sale_number', 'saleNumber'),
    transactionDate: _dateTime(
      json['transaction_date'] ?? json['transactionDate'],
    ),
    paymentMethod: _string(json, 'payment_method', 'paymentMethod'),
    cashierName: _cashierName(json),
    items: (json['items'] as List<dynamic>? ?? const [])
        .map((item) => CashSaleItem.fromJson(item as Map<String, dynamic>))
        .toList(),
    subtotal: _number(json, 'subtotal', 'subtotal'),
    discountTotal: (json['total_discount'] ?? json['discountTotal']) as num,
    grandTotal: (json['grand_total'] ?? json['grandTotal']) as num,
    cashReceived: (json['cash_received'] ?? json['cashReceived']) as num,
    changeAmount: (json['change_amount'] ?? json['changeAmount']) as num,
    notes: json['notes'] as String?,
  );
}

class CashSaleItem {
  const CashSaleItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.finalUnitPrice,
    required this.subtotal,
  });

  final String productName;
  final int quantity;
  final num unitPrice;
  final num discount;
  final num finalUnitPrice;
  final num subtotal;

  factory CashSaleItem.fromJson(Map<String, dynamic> json) => CashSaleItem(
    productName: _string(json, 'product_name', 'productName'),
    quantity: (json['quantity'] as num).toInt(),
    unitPrice: (json['unit_price'] ?? json['unitPrice']) as num,
    discount: (json['discount'] ?? json['discountAmount'] ?? 0) as num,
    finalUnitPrice: (json['final_unit_price'] ?? json['finalUnitPrice']) as num,
    subtotal: json['subtotal'] as num,
  );

  Map<String, dynamic> toJson() => {
    'product_name': productName,
    'quantity': quantity,
    'unit_price': unitPrice,
    'discount': discount,
    'final_unit_price': finalUnitPrice,
    'subtotal': subtotal,
  };
}

DateTime? _dateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

String _string(Map<String, dynamic> json, String snake, String camel) =>
    (json[snake] ?? json[camel]) as String;

num _number(Map<String, dynamic> json, String snake, String camel) =>
    (json[snake] ?? json[camel]) as num;

String _cashierName(Map<String, dynamic> json) {
  final cashier = json['cashier'];
  if (cashier is Map) {
    final name = cashier['name'];
    if (name is String) return name;
  }
  return (json['cashierName'] as String?) ?? '';
}
