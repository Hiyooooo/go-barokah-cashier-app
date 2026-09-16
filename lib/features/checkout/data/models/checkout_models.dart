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
    status: (json['status'] ?? 'COMPLETED').toString(),
    saleNumber: _string(json, 'sale_number', 'saleNumber'),
    transactionDate: _dateTime(
      json['transaction_date'] ??
          json['transactionDate'] ??
          json['created_at'] ??
          json['createdAt'],
    ),
    paymentMethod: _string(json, 'payment_method', 'paymentMethod'),
    cashierName: _cashierName(json),
    items: _items(json['items']),
    subtotal: _number(json, 'subtotal', 'subtotal'),
    discountTotal: _number(
      json,
      'total_discount',
      'discount_total',
      fallback: 'discountTotal',
    ),
    grandTotal: _number(json, 'grand_total', 'grandTotal'),
    cashReceived: _number(json, 'cash_received', 'cashReceived'),
    changeAmount: _number(json, 'change_amount', 'changeAmount'),
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

  factory CashSaleItem.fromJson(Map<String, dynamic> json) {
    final quantity = _int(json['quantity']);
    final unitPrice = _num(json['unit_price'] ?? json['unitPrice']);
    final subtotal = _num(json['subtotal']);
    // ponytail: derive missing legacy unit prices; use backend field when available.
    final finalUnitPrice =
        _optionalNum(json['final_unit_price'] ?? json['finalUnitPrice']) ??
        (quantity > 0 ? subtotal / quantity : unitPrice);

    return CashSaleItem(
      productName: _string(json, 'product_name', 'productName'),
      quantity: quantity,
      unitPrice: unitPrice,
      discount: _num(
        json['discount'] ??
            json['discount_amount'] ??
            json['discountAmount'] ??
            0,
      ),
      finalUnitPrice: finalUnitPrice,
      subtotal: subtotal,
    );
  }

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
    (json[snake] ?? json[camel]).toString();

num _number(
  Map<String, dynamic> json,
  String first,
  String second, {
  String? fallback,
}) => _num(
  json[first] ?? json[second] ?? (fallback == null ? null : json[fallback]),
);

List<CashSaleItem> _items(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => CashSaleItem.fromJson(item.cast<String, dynamic>()))
          .toList()
    : const [];

num _num(Object? value) => value is num ? value : num.parse(value.toString());

num? _optionalNum(Object? value) => value == null ? null : _num(value);

int _int(Object? value) => _num(value).toInt();

String _cashierName(Map<String, dynamic> json) {
  final cashier = json['cashier'];
  if (cashier is Map) {
    final name = cashier['name'];
    if (name is String) return name;
  }
  return (json['cashierName'] as String?) ?? '';
}
