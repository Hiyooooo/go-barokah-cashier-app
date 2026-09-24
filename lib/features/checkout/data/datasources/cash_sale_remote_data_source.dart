import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../models/checkout_models.dart';

class CashSaleRemoteDataSource {
  const CashSaleRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<CashSaleResult> createCashSale({
    required List<int> cartItemIds,
    num cashReceived = 0,
    String paymentMethod = 'CASH',
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.request<Map<String, dynamic>>(
      '/api/cash-sales',
      method: 'POST',
      data: {
        'cart_item_ids': cartItemIds,
        if (paymentMethod != 'CASH') 'payment_method': paymentMethod,
        'cash_received': cashReceived,
      },
      options: Options(
        headers: {
          'Content-Type': Headers.jsonContentType,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
    final payload = response.data!['data'];
    final data = payload is Map
        ? payload.cast<String, dynamic>()
        : response.data!;
    final result = CashSaleResult.fromJson(data);
    // ponytail: dev-only hint when QRIS arrives without QR payload; remove if noisy.
    if (result.paymentMethod == 'QRIS' &&
        result.status == 'PENDING' &&
        result.qrString == null &&
        result.qrCodeUrl == null) {
      debugPrint(
        '[GO_BAROKAH_QRIS] PENDING without QR payload. keys=${data.keys.toList()}',
      );
    }
    return result;
  }

  Future<CashSaleResult> cancelCashSale(String saleNumber) async {
    final response = await _apiClient.request<Map<String, dynamic>>(
      '/api/cash-sales/$saleNumber/cancel',
      method: 'POST',
    );
    final payload = response.data!['data'];
    final data = payload is Map
        ? payload.cast<String, dynamic>()
        : response.data!;
    return CashSaleResult.fromJson(data);
  }

  Future<CashSaleResult> getCashSale(String saleNumber) async {
    final response = await _apiClient.request<Map<String, dynamic>>(
      '/api/cash-sales/$saleNumber',
    );
    final payload = response.data!['data'];
    final data = payload is Map
        ? payload.cast<String, dynamic>()
        : response.data!;
    return CashSaleResult.fromJson(data);
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
