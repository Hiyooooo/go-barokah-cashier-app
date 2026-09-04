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
    saleNumber: json['sale_number'] as String,
    createdAt: _dateTime(json['created_at']),
    cashierName:
        (json['cashier'] as Map<String, dynamic>?)?['name'] as String? ?? '',
    paymentMethod: json['payment_method'] as String,
    items: (json['items'] as List<dynamic>? ?? const [])
        .map((item) => ReceiptItem.fromJson(item as Map<String, dynamic>))
        .toList(),
    subtotal: json['subtotal'] as num,
    discountTotal: json['discount_total'] as num,
    grandTotal: json['grand_total'] as num,
    cashReceived: json['cash_received'] as num,
    changeAmount: json['change_amount'] as num,
    notes: json['notes'] as String?,
  );
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
    productId: (json['product_id'] as num?)?.toInt(),
    productName: json['product_name'] as String,
    quantity: (json['quantity'] as num).toInt(),
    unitPrice: json['unit_price'] as num,
    discountAmount: json['discount_amount'] as num,
    finalUnitPrice: json['final_unit_price'] as num,
    subtotal: json['subtotal'] as num,
  );
}

DateTime? _dateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
