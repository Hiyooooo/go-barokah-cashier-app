import '../../../../core/network/api_client.dart';
import '../datasources/cash_sale_remote_data_source.dart';
import '../models/checkout_models.dart';

class CashSaleRepository {
  CashSaleRepository({required ApiClient apiClient})
    : _dataSource = CashSaleRemoteDataSource(apiClient);

  final CashSaleRemoteDataSource _dataSource;

  Future<CashSaleResult> createCashSale({
    required List<int> cartItemIds,
    num cashReceived = 0,
    String paymentMethod = 'CASH',
    required String idempotencyKey,
  }) => _dataSource.createCashSale(
    cartItemIds: cartItemIds,
    cashReceived: cashReceived,
    paymentMethod: paymentMethod,
    idempotencyKey: idempotencyKey,
  );

  Future<CashSaleResult> cancelCashSale(String saleNumber) =>
      _dataSource.cancelCashSale(saleNumber);

  Future<CashSaleResult> getCashSale(String saleNumber) =>
      _dataSource.getCashSale(saleNumber);
}
