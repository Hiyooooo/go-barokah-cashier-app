class CashSaleHistoryResponse {
  const CashSaleHistoryResponse({required this.items, this.meta});

  final List<CashSaleHistoryItem> items;
  final PaginationMeta? meta;

  factory CashSaleHistoryResponse.fromJson(Map<String, dynamic> json) =>
      CashSaleHistoryResponse(
        items: (json['data'] as List<dynamic>? ?? const [])
            .map(
              (item) =>
                  CashSaleHistoryItem.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
        meta: _pagination(json['meta']),
      );
}

class CashSaleHistoryItem {
  const CashSaleHistoryItem({
    required this.saleNumber,
    required this.paymentMethod,
    required this.subtotal,
    required this.discountTotal,
    required this.grandTotal,
    required this.cashReceived,
    required this.changeAmount,
    required this.createdAt,
  });

  final String saleNumber;
  final String paymentMethod;
  final num subtotal;
  final num discountTotal;
  final num grandTotal;
  final num cashReceived;
  final num changeAmount;
  final DateTime? createdAt;

  factory CashSaleHistoryItem.fromJson(Map<String, dynamic> json) =>
      CashSaleHistoryItem(
        saleNumber: json['saleNumber'] as String,
        paymentMethod: json['paymentMethod'] as String,
        subtotal: json['subtotal'] as num,
        discountTotal: json['discountTotal'] as num,
        grandTotal: json['grandTotal'] as num,
        cashReceived: json['cashReceived'] as num,
        changeAmount: json['changeAmount'] as num,
        createdAt: _dateTime(json['createdAt']),
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

PaginationMeta? _pagination(Object? value) =>
    value is Map<String, dynamic> ? PaginationMeta.fromJson(value) : null;

DateTime? _dateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
