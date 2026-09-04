import 'dart:math';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/checkout_models.dart';

class CashSaleRemoteDataSource {
  const CashSaleRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<CashSaleResult> createCashSale({
    required List<int> cartItemIds,
    required num cashReceived,
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.request<Map<String, dynamic>>(
      '/api/cash-sales',
      method: 'POST',
      data: {'cart_item_ids': cartItemIds, 'cash_received': cashReceived},
      options: Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return CashSaleResult.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }
}

String newIdempotencyKey() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}
