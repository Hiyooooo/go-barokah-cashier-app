import 'dart:async';

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
  String? _lastPaymentMethod;
  PendingCashSale? _pending;
  String? _cashierId;
  Timer? _pollingTimer;

  CashSaleRepository get _repository => ref.read(cashSaleRepositoryProvider);

  @override
  Future<CashSaleResult?> build() async {
    ref.onDispose(_stopPolling);
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
    final result = await _send(_pending!);
    if (result.status == 'PENDING') {
      _startPolling(result.saleNumber);
    }
    return result;
  }

  Future<void> submit({
    required List<int> cartItemIds,
    num cashReceived = 0,
    String paymentMethod = 'CASH',
  }) async {
    if (state.isLoading || state.valueOrNull != null) return;
    if (_cashierId == null) return;
    if (_pending != null &&
        !_samePayload(cartItemIds, cashReceived, paymentMethod)) {
      return;
    }
    final store = ref.read(pendingCashSaleStoreProvider);
    if (!_samePayload(cartItemIds, cashReceived, paymentMethod)) {
      _idempotencyKey = null;
      _lastCartItemIds = List.unmodifiable(cartItemIds);
      _lastCashReceived = cashReceived;
      _lastPaymentMethod = paymentMethod;
    }
    _idempotencyKey ??= newIdempotencyKey();
    final pending = PendingCashSale(
      idempotencyKey: _idempotencyKey!,
      cartItemIds: List.unmodifiable(cartItemIds),
      cashReceived: cashReceived,
      paymentMethod: paymentMethod,
      cashierId: _cashierId,
      createdAt: DateTime.now().toUtc(),
    );
    _pending = pending;
    _restorePayload(pending);
    state = const AsyncLoading<CashSaleResult?>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await store.write(pending);
      final result = await _send(pending);
      if (result.status == 'PENDING') {
        _startPolling(result.saleNumber);
      }
      return result;
    });
  }

  Future<CashSaleResult> _send(PendingCashSale pending) async {
    try {
      final result = await _repository.createCashSale(
        cartItemIds: pending.cartItemIds,
        cashReceived: pending.cashReceived,
        paymentMethod: pending.paymentMethod,
        idempotencyKey: pending.idempotencyKey,
      );
      final nextStatus = result.status == 'COMPLETED' ? 'completed' : 'pending';
      final updated = PendingCashSale(
        idempotencyKey: pending.idempotencyKey,
        cartItemIds: pending.cartItemIds,
        cashReceived: pending.cashReceived,
        paymentMethod: pending.paymentMethod,
        cashierId: pending.cashierId,
        createdAt: pending.createdAt,
        status: nextStatus,
        result: result.toJson(),
      );
      await ref.read(pendingCashSaleStoreProvider).write(updated);
      _pending = updated;
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

  void _startPolling(String saleNumber) {
    _stopPolling();
    // ponytail: simple periodic timer for polling; cancel on terminal states or dispose.
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final current = await _repository.getCashSale(saleNumber);
        if (current.status == 'COMPLETED') {
          _stopPolling();
          final completed = PendingCashSale(
            idempotencyKey: _pending?.idempotencyKey ?? '',
            cartItemIds: _pending?.cartItemIds ?? const [],
            cashReceived: current.cashReceived,
            paymentMethod: current.paymentMethod,
            cashierId: _cashierId,
            createdAt: _pending?.createdAt,
            status: 'completed',
            result: current.toJson(),
          );
          await ref.read(pendingCashSaleStoreProvider).write(completed);
          _pending = completed;
          state = AsyncData(current);
        } else if (current.status == 'CANCELLED' ||
            current.status == 'FAILED' ||
            current.status == 'EXPIRED') {
          _stopPolling();
          await ref.read(pendingCashSaleStoreProvider).clear();
          _pending = null;
          state = AsyncError(
            ApiException(
              type: ApiErrorType.badRequest,
              message: 'Transaksi ${current.status.toLowerCase()}.',
            ),
            StackTrace.current,
          );
        }
      } catch (_) {
        // Ignore periodic network blips while polling; next tick retries.
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> cancelPendingSale() async {
    _stopPolling();
    final currentSaleNumber =
        state.valueOrNull?.saleNumber ??
        _pending?.result?['sale_number'] as String?;
    if (currentSaleNumber != null) {
      try {
        await _repository.cancelCashSale(currentSaleNumber);
      } catch (_) {
        // Continue clearing client state even if backend cancellation failed.
      }
    }
    await finalizeSale();
  }

  Future<void> finalizeSale() async {
    _stopPolling();
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
    _lastPaymentMethod = pending.paymentMethod;
  }

  bool _belongsToCurrentCashier(PendingCashSale pending) =>
      _cashierId != null &&
      pending.cashierId != null &&
      pending.cashierId == _cashierId;

  bool _samePayload(
    List<int> cartItemIds,
    num cashReceived,
    String paymentMethod,
  ) {
    if (_lastCashReceived != cashReceived ||
        _lastPaymentMethod != paymentMethod ||
        _lastCartItemIds?.length != cartItemIds.length) {
      return false;
    }
    for (var index = 0; index < cartItemIds.length; index++) {
      if (_lastCartItemIds![index] != cartItemIds[index]) return false;
    }
    return true;
  }
}
