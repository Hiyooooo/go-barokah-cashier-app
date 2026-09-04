import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/cart_models.dart';
import '../../data/repositories/cart_repository.dart';

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepository(apiClient: ref.watch(apiClientProvider)),
);

final cartProvider = AsyncNotifierProvider<CartNotifier, Cart>(
  CartNotifier.new,
);

class CartNotifier extends AsyncNotifier<Cart> {
  CartRepository get _repository => ref.read(cartRepositoryProvider);

  @override
  Future<Cart> build() => _repository.getCart();

  Future<void> addItem(int productId, {int quantity = 1}) =>
      _mutate(() => _repository.addItem(productId, quantity));

  Future<void> updateItem(int productId, int quantity) =>
      _mutate(() => _repository.updateItem(productId, quantity));

  Future<void> removeItem(int productId) =>
      _mutate(() => _repository.removeItem(productId));

  Future<void> clearCart() => _mutate(_repository.clearCart);

  Future<void> refreshCart() async {
    state = await AsyncValue.guard(_repository.getCart);
  }

  Future<void> _mutate(Future<Cart> Function() operation) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(operation);
  }
}
