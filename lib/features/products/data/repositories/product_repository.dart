import '../../../../core/network/api_client.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/product_models.dart';

class ProductRepository {
  ProductRepository({required ApiClient apiClient})
    : _dataSource = ProductRemoteDataSource(apiClient);

  final ProductRemoteDataSource _dataSource;

  Future<ProductPage> getProducts({
    String? query,
    int? categoryId,
    required int page,
    required int limit,
  }) => _dataSource.getProducts(
    query: query,
    categoryId: categoryId,
    page: page,
    limit: limit,
  );

  Future<Product> getProduct(int id) => _dataSource.getProduct(id);

  Future<List<ProductCategory>> getCategories() => _dataSource.getCategories();
}
