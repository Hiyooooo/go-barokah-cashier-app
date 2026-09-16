import '../../../../core/network/api_client.dart';
import '../models/cash_sale_history_models.dart';

class CashSaleHistoryRemoteDataSource {
  const CashSaleHistoryRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<CashSaleHistoryResponse> getHistory({
    required int page,
    required int limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (startDate != null) params['start_date'] = _date(startDate);
    if (endDate != null) params['end_date'] = _date(endDate);

    final response = await _apiClient.request<Map<String, dynamic>>(
      '/api/cash-sales',
      queryParameters: params,
    );
    return CashSaleHistoryResponse.fromJson(response.data!);
  }

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
