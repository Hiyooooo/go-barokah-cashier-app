class Receipt {
  const Receipt({
    this.status = 'COMPLETED',
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

  final String status;
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
    status: (json['status'] ?? 'COMPLETED').toString(),
    saleNumber: _string(json, 'sale_number', 'saleNumber'),
    createdAt: _dateTime(
      json['transaction_date'] ??
          json['transactionDate'] ??
          json['created_at'] ??
          json['createdAt'],
    ),
    cashierName: _cashierName(json),
    paymentMethod: _string(json, 'payment_method', 'paymentMethod'),
    items: _items(json['items']),
    subtotal: _number(json, 'subtotal', 'subtotal'),
    discountTotal: _number(
      json,
      'discount_total',
      'total_discount',
      fallback: 'discountTotal',
    ),
    grandTotal: _number(json, 'grand_total', 'grandTotal'),
    cashReceived: _number(json, 'cash_received', 'cashReceived'),
    changeAmount: _number(json, 'change_amount', 'changeAmount'),
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

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    final quantity = _int(json['quantity']);
    final unitPrice = _num(json['unit_price'] ?? json['unitPrice']);
    final subtotal = _num(json['subtotal']);
    // ponytail: derive missing legacy unit prices; use backend field when available.
    final finalUnitPrice =
        _optionalNum(json['final_unit_price'] ?? json['finalUnitPrice']) ??
        (quantity > 0 ? subtotal / quantity : unitPrice);

    return ReceiptItem(
      productId: _optionalInt(json['product_id'] ?? json['productId']),
      productName: _string(json, 'product_name', 'productName'),
      quantity: quantity,
      unitPrice: unitPrice,
      discountAmount: _num(
        json['discount'] ??
            json['discount_amount'] ??
            json['discountAmount'] ??
            0,
      ),
      finalUnitPrice: finalUnitPrice,
      subtotal: subtotal,
    );
  }
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

num _num(Object? value) => value is num ? value : num.parse(value.toString());

num? _optionalNum(Object? value) => value == null ? null : _num(value);

int _int(Object? value) => _num(value).toInt();

int? _optionalInt(Object? value) => value == null ? null : _int(value);

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
