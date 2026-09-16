import '../../../../core/network/api_client.dart';
import '../datasources/cash_sale_remote_data_source.dart';
import '../models/checkout_models.dart';

class CashSaleRepository {
  CashSaleRepository({required ApiClient apiClient})
    : _dataSource = CashSaleRemoteDataSource(apiClient);

  final CashSaleRemoteDataSource _dataSource;

  Future<CashSaleResult> createCashSale({
    required List<int> cartItemIds,
    required num cashReceived,
    required String idempotencyKey,
  }) => _dataSource.createCashSale(
    cartItemIds: cartItemIds,
    cashReceived: cashReceived,
    idempotencyKey: idempotencyKey,
  );
}
