import '../../../../core/network/api_client.dart';
import '../models/receipt_models.dart';

class ReceiptRemoteDataSource {
  const ReceiptRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Receipt> getReceipt(String saleNumber) async {
    final response = await _apiClient.request<Map<String, dynamic>>(
      '/api/cash-sales/$saleNumber',
    );
    return Receipt.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}
