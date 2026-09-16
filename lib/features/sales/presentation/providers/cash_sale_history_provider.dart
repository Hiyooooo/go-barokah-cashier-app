import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/cash_sale_history_models.dart';
import '../../data/repositories/cash_sale_history_repository.dart';

final cashSaleHistoryRepositoryProvider = Provider<CashSaleHistoryRepository>(
  (ref) => CashSaleHistoryRepository(apiClient: ref.watch(apiClientProvider)),
);

final cashSaleHistoryProvider =
    AsyncNotifierProvider<CashSaleHistoryNotifier, CashSaleHistoryResponse>(
      CashSaleHistoryNotifier.new,
    );

class CashSaleHistoryNotifier extends AsyncNotifier<CashSaleHistoryResponse> {
  static const pageSize = 20;

  DateTime? startDate;
  DateTime? endDate;
  int page = 1;
  int _requestVersion = 0;

  CashSaleHistoryRepository get _repository =>
      ref.read(cashSaleHistoryRepositoryProvider);

  @override
  Future<CashSaleHistoryResponse> build() => _load(
    requestedPage: page,
    requestedStartDate: startDate,
    requestedEndDate: endDate,
  );

  Future<CashSaleHistoryResponse> _load({
    required int requestedPage,
    DateTime? requestedStartDate,
    DateTime? requestedEndDate,
  }) => _repository.getHistory(
    page: requestedPage,
    limit: pageSize,
    startDate: requestedStartDate,
    endDate: requestedEndDate,
  );

  Future<void> applyDates({DateTime? startDate, DateTime? endDate}) async {
    this.startDate = startDate;
    this.endDate = endDate;
    page = 1;
    final requestVersion = ++_requestVersion;
    final previous = state;
    state = const AsyncLoading<CashSaleHistoryResponse>().copyWithPrevious(
      previous,
    );
    final nextState = await AsyncValue.guard(
      () => _load(
        requestedPage: page,
        requestedStartDate: startDate,
        requestedEndDate: endDate,
      ),
    );
    if (requestVersion == _requestVersion) state = nextState;
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == this.page) return;
    this.page = page;
    final requestVersion = ++_requestVersion;
    final previous = state;
    state = const AsyncLoading<CashSaleHistoryResponse>().copyWithPrevious(
      previous,
    );
    final nextState = await AsyncValue.guard(
      () => _load(
        requestedPage: page,
        requestedStartDate: startDate,
        requestedEndDate: endDate,
      ),
    );
    if (requestVersion == _requestVersion) state = nextState;
  }
}
