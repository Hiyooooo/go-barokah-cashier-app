import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
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

  CashSaleRepository get _repository => ref.read(cashSaleRepositoryProvider);

  @override
  Future<CashSaleResult?> build() async => null;

  Future<void> submit({
    required List<int> cartItemIds,
    required num cashReceived,
  }) async {
    if (state.isLoading || state.valueOrNull != null) return;
    if (!_samePayload(cartItemIds, cashReceived)) {
      _idempotencyKey = null;
      _lastCartItemIds = List.unmodifiable(cartItemIds);
      _lastCashReceived = cashReceived;
    }
    _idempotencyKey ??= newIdempotencyKey();
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.createCashSale(
        cartItemIds: cartItemIds,
        cashReceived: cashReceived,
        idempotencyKey: _idempotencyKey!,
      ),
    );
  }

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
