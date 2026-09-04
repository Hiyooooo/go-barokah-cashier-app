import '../../../../core/network/api_client.dart';
import '../models/product_models.dart';

class ProductRemoteDataSource {
  const ProductRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<ProductPage> getProducts({
    String? query,
    int? categoryId,
    required int page,
    required int limit,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (categoryId != null) params['category_id'] = categoryId;

    final response = await _apiClient.request<Map<String, dynamic>>(
      '/api/products',
      queryParameters: params,
    );
    return ProductPage.fromJson(response.data!);
  }

  Future<Product> getProduct(int id) async {
    final response = await _apiClient.request<Map<String, dynamic>>(
      '/api/products/$id',
    );
    return Product.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<List<ProductCategory>> getCategories() async {
    final response = await _apiClient.request<Map<String, dynamic>>(
      '/api/products/category',
    );
    return parseCategories(response.data!);
  }
}
