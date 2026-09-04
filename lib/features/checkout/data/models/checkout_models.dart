class CashSaleResult {
  const CashSaleResult({
    required this.saleNumber,
    required this.subtotal,
    required this.discountTotal,
    required this.grandTotal,
    required this.cashReceived,
    required this.changeAmount,
  });

  final String saleNumber;
  final num subtotal;
  final num discountTotal;
  final num grandTotal;
  final num cashReceived;
  final num changeAmount;

  factory CashSaleResult.fromJson(Map<String, dynamic> json) => CashSaleResult(
    saleNumber: json['saleNumber'] as String,
    subtotal: json['subtotal'] as num,
    discountTotal: json['discountTotal'] as num,
    grandTotal: json['grandTotal'] as num,
    cashReceived: json['cashReceived'] as num,
    changeAmount: json['changeAmount'] as num,
  );
}
