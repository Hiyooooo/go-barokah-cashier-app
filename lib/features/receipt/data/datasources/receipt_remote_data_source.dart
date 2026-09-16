import '../../../../core/network/api_client.dart';
import '../models/receipt_models.dart';

class ReceiptRemoteDataSource {
  const ReceiptRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Receipt> getReceipt(String saleNumber) async {
    final response = await _apiClient.request<Map<String, dynamic>>(
      '/api/cash-sales/$saleNumber',
    );
    final payload = response.data!['data'];
    final data = payload is Map
        ? payload.cast<String, dynamic>()
        : response.data!;
    return Receipt.fromJson(data);
  }
}
