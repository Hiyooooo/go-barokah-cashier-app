import '../../../../core/network/api_client.dart';
import '../datasources/receipt_remote_data_source.dart';
import '../models/receipt_models.dart';

class ReceiptRepository {
  ReceiptRepository({required ApiClient apiClient})
    : _dataSource = ReceiptRemoteDataSource(apiClient);

  final ReceiptRemoteDataSource _dataSource;

  Future<Receipt> getReceipt(String saleNumber) =>
      _dataSource.getReceipt(saleNumber);
}
