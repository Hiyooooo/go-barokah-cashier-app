import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/pending_cash_sale_store.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/checkout_models.dart';
import '../../data/repositories/cash_sale_repository.dart';
import '../../data/datasources/cash_sale_remote_data_source.dart';

final cashSaleRepositoryProvider = Provider<CashSaleRepository>(
  (ref) => CashSaleRepository(apiClient: ref.watch(apiClientProvider)),
);

final checkoutProvider =
    AsyncNotifierProvider<CheckoutNotifier, CashSaleResult?>(
      CheckoutNotifier.new,
    );

class CheckoutNotifier extends AsyncNotifier<CashSaleResult?> {
  String? _idempotencyKey;
  List<int>? _lastCartItemIds;
  num? _lastCashReceived;
  PendingCashSale? _pending;
  String? _cashierId;

  CashSaleRepository get _repository => ref.read(cashSaleRepositoryProvider);

  @override
  Future<CashSaleResult?> build() async {
    _cashierId = (await ref.watch(authProvider.future))?.id;
    _pending = await ref.read(pendingCashSaleStoreProvider).read();
    if (_pending == null) return null;
    if (!_belongsToCurrentCashier(_pending!)) {
      _pending = null;
      return null;
    }
    _restorePayload(_pending!);
    if (_pending!.status == 'completed' && _pending!.result != null) {
      return CashSaleResult.fromJson(_pending!.result!);
    }
    return _send(_pending!);
  }

  Future<void> submit({
    required List<int> cartItemIds,
    required num cashReceived,
  }) async {
    if (state.isLoading || state.valueOrNull != null) return;
    if (_cashierId == null) return;
    if (_pending != null && !_samePayload(cartItemIds, cashReceived)) {
      return;
    }
    final store = ref.read(pendingCashSaleStoreProvider);
    if (!_samePayload(cartItemIds, cashReceived)) {
      _idempotencyKey = null;
      _lastCartItemIds = List.unmodifiable(cartItemIds);
      _lastCashReceived = cashReceived;
    }
    _idempotencyKey ??= newIdempotencyKey();
    final pending = PendingCashSale(
      idempotencyKey: _idempotencyKey!,
      cartItemIds: List.unmodifiable(cartItemIds),
      cashReceived: cashReceived,
      cashierId: _cashierId,
      createdAt: DateTime.now().toUtc(),
    );
    _pending = pending;
    await store.write(pending);
    _restorePayload(pending);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _send(pending));
  }

  Future<CashSaleResult> _send(PendingCashSale pending) async {
    try {
      final result = await _repository.createCashSale(
        cartItemIds: pending.cartItemIds,
        cashReceived: pending.cashReceived,
        idempotencyKey: pending.idempotencyKey,
      );
      final completed = PendingCashSale(
        idempotencyKey: pending.idempotencyKey,
        cartItemIds: pending.cartItemIds,
        cashReceived: pending.cashReceived,
        cashierId: pending.cashierId,
        createdAt: pending.createdAt,
        status: 'completed',
        result: result.toJson(),
      );
      await ref.read(pendingCashSaleStoreProvider).write(completed);
      _pending = completed;
      return result;
    } on ApiException catch (error) {
      if (error.type == ApiErrorType.badRequest ||
          error.type == ApiErrorType.conflict) {
        await ref.read(pendingCashSaleStoreProvider).clear();
        _pending = null;
        _idempotencyKey = null;
      }
      rethrow;
    }
  }

  Future<void> finalizeSale() async {
    await ref.read(pendingCashSaleStoreProvider).clear();
    _pending = null;
    state = const AsyncData(null);
  }

  Future<void> resetCompletedSale() async {
    if (_pending?.status != 'completed' && state.valueOrNull == null) return;
    await finalizeSale();
  }

  void _restorePayload(PendingCashSale pending) {
    _idempotencyKey = pending.idempotencyKey;
    _lastCartItemIds = List.unmodifiable(pending.cartItemIds);
    _lastCashReceived = pending.cashReceived;
  }

  bool _belongsToCurrentCashier(PendingCashSale pending) =>
      _cashierId != null &&
      pending.cashierId != null &&
      pending.cashierId == _cashierId;

  bool _samePayload(List<int> cartItemIds, num cashReceived) {
    if (_lastCashReceived != cashReceived ||
        _lastCartItemIds?.length != cartItemIds.length) {
      return false;
    }
    for (var index = 0; index < cartItemIds.length; index++) {
      if (_lastCartItemIds![index] != cartItemIds[index]) return false;
    }
    return true;
  }
}
