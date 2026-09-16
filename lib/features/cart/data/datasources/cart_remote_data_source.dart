import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../models/cart_models.dart';

class CartRemoteDataSource {
  const CartRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<Cart> getCart() async {
    final response = await _apiClient.request<Map<String, dynamic>>(
      '/api/carts',
    );
    return Cart.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<Cart> addItem(int productId, int quantity) async {
    final response = await _apiClient.request<Map<String, dynamic>>(
      '/api/carts/items',
      method: 'POST',
      data: {'product_id': productId, 'quantity': quantity},
    );
    return _cart(response);
  }

  Future<Cart> updateItem(int productId, int quantity) async {
    final response = await _apiClient.request<Map<String, dynamic>>(
      '/api/carts/items/$productId',
      method: 'PATCH',
      data: {'quantity': quantity},
    );
    return _cart(response);
  }

  Future<Cart> removeItem(int productId) async {
    final response = await _apiClient.request<Map<String, dynamic>>(
      '/api/carts/items/$productId',
      method: 'DELETE',
    );
    return _cart(response);
  }

  Future<Cart> clearCart() async {
    final response = await _apiClient.request<Map<String, dynamic>>(
      '/api/carts',
      method: 'DELETE',
    );
    return _cart(response);
  }

  Cart _cart(Response<Map<String, dynamic>> response) =>
      Cart.fromJson(response.data!['data'] as Map<String, dynamic>);
}
