import '../../../../core/network/api_client.dart';
import '../datasources/cash_sale_history_remote_data_source.dart';
import '../models/cash_sale_history_models.dart';

class CashSaleHistoryRepository {
  CashSaleHistoryRepository({required ApiClient apiClient})
    : _dataSource = CashSaleHistoryRemoteDataSource(apiClient);

  final CashSaleHistoryRemoteDataSource _dataSource;

  Future<CashSaleHistoryResponse> getHistory({
    required int page,
    required int limit,
    DateTime? startDate,
    DateTime? endDate,
  }) => _dataSource.getHistory(
    page: page,
    limit: limit,
    startDate: startDate,
    endDate: endDate,
  );
}
