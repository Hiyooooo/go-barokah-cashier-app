class CashSaleHistoryResponse {
  const CashSaleHistoryResponse({required this.items, this.meta});

  final List<CashSaleHistoryItem> items;
  final PaginationMeta? meta;

  factory CashSaleHistoryResponse.fromJson(Map<String, dynamic> json) =>
      CashSaleHistoryResponse(
        items: _items(json['data'] ?? json['items']),
        meta: _pagination(
          json['meta'] ??
              (json['data'] is Map ? (json['data'] as Map)['meta'] : null),
        ),
      );
}

class CashSaleHistoryItem {
  const CashSaleHistoryItem({
    required this.saleNumber,
    required this.paymentMethod,
    required this.grandTotal,
    required this.createdAt,
  });

  final String saleNumber;
  final String paymentMethod;
  final num grandTotal;
  final DateTime? createdAt;

  factory CashSaleHistoryItem.fromJson(Map<String, dynamic> json) {
    final saleNumber = _string(json, 'sale_number', 'saleNumber');
    final paymentMethod = _string(json, 'payment_method', 'paymentMethod');
    final date = json['transaction_date'] ?? json['createdAt'];
    return CashSaleHistoryItem(
      saleNumber: saleNumber,
      paymentMethod: paymentMethod,
      grandTotal: _number(json, 'grand_total', 'grandTotal'),
      createdAt: _dateTime(date),
    );
  }
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
    totalPages: ((json['totalPages'] ?? json['total_pages']) as num).toInt(),
  );
}

PaginationMeta? _pagination(Object? value) =>
    value is Map<String, dynamic> ? PaginationMeta.fromJson(value) : null;

List<CashSaleHistoryItem> _items(Object? value) {
  if (value is Map) return _items(value['items'] ?? value['data']);
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => CashSaleHistoryItem.fromJson(item.cast<String, dynamic>()))
      .toList();
}

String _string(Map<String, dynamic> json, String snake, String camel) =>
    (json[snake] ?? json[camel]) as String;

num _number(Map<String, dynamic> json, String snake, String camel) =>
    (json[snake] ?? json[camel]) as num;

DateTime? _dateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
