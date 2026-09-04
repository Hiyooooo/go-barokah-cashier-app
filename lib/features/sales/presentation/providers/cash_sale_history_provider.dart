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

  CashSaleHistoryRepository get _repository =>
      ref.read(cashSaleHistoryRepositoryProvider);

  @override
  Future<CashSaleHistoryResponse> build() => _load();

  Future<CashSaleHistoryResponse> _load() => _repository.getHistory(
    page: page,
    limit: pageSize,
    startDate: startDate,
    endDate: endDate,
  );

  Future<void> applyDates({DateTime? startDate, DateTime? endDate}) async {
    this.startDate = startDate;
    this.endDate = endDate;
    page = 1;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page == this.page) return;
    this.page = page;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}
