import '../../../../core/network/api_client.dart';
import '../datasources/cart_remote_data_source.dart';
import '../models/cart_models.dart';

class CartRepository {
  CartRepository({required ApiClient apiClient})
    : _dataSource = CartRemoteDataSource(apiClient);

  final CartRemoteDataSource _dataSource;

  Future<Cart> getCart() => _dataSource.getCart();
  Future<Cart> addItem(int productId, int quantity) =>
      _dataSource.addItem(productId, quantity);
  Future<Cart> updateItem(int productId, int quantity) =>
      _dataSource.updateItem(productId, quantity);
  Future<Cart> removeItem(int productId) => _dataSource.removeItem(productId);
  Future<Cart> clearCart() => _dataSource.clearCart();
}
