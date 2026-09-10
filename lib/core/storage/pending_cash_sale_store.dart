import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final pendingCashSaleStoreProvider = Provider<PendingCashSaleStore>(
  (ref) => PendingCashSaleStore(),
);

class PendingCashSaleStore {
  PendingCashSaleStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'pending_cash_sale';
  final FlutterSecureStorage _storage;

  Future<PendingCashSale?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    return PendingCashSale.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> write(PendingCashSale value) =>
      _storage.write(key: _key, value: jsonEncode(value.toJson()));

  Future<void> clear() => _storage.delete(key: _key);
}

class PendingCashSale {
  const PendingCashSale({
    required this.idempotencyKey,
    required this.cartItemIds,
    required this.cashReceived,
    this.cashierId,
    this.createdAt,
    this.status = 'pending',
    this.result,
  });

  final String idempotencyKey;
  final List<int> cartItemIds;
  final num cashReceived;
  final String? cashierId;
  final DateTime? createdAt;
  final String status;
  final Map<String, dynamic>? result;

  Map<String, dynamic> toJson() => {
    'idempotency_key': idempotencyKey,
    'cart_item_ids': cartItemIds,
    'cash_received': cashReceived,
    if (cashierId != null) 'cashier_id': cashierId,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    'status': status,
    if (result != null) 'result': result,
  };

  factory PendingCashSale.fromJson(Map<String, dynamic> json) =>
      PendingCashSale(
        idempotencyKey: json['idempotency_key'] as String,
        cartItemIds: (json['cart_item_ids'] as List<dynamic>)
            .map((id) => (id as num).toInt())
            .toList(),
        cashReceived: json['cash_received'] as num,
        cashierId: json['cashier_id'] as String?,
        createdAt: _dateTime(json['created_at']),
        status: json['status'] as String? ?? 'pending',
        result: (json['result'] as Map?)?.cast<String, dynamic>(),
      );
}

DateTime? _dateTime(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
