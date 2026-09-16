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
  final _mutatingProducts = <int>{};
  // ponytail: serialize cart writes; parallel writes can return stale snapshots.
  // Replace with per-item versioning only if measured throughput requires it.
  Future<void>? _mutationQueue;

  bool isMutatingProduct(int productId) =>
      _mutatingProducts.contains(productId);

  CartRepository get _repository => ref.read(cartRepositoryProvider);

  @override
  Future<Cart> build() => _repository.getCart();

  Future<void> addItem(int productId, {int quantity = 1}) =>
      _mutateProduct(productId, () => _repository.addItem(productId, quantity));

  Future<void> updateItem(int productId, int quantity) => _mutateProduct(
    productId,
    () => _repository.updateItem(productId, quantity),
  );

  Future<void> removeItem(int productId) =>
      _mutateProduct(productId, () => _repository.removeItem(productId));

  Future<void> clearCart() => _mutate(_repository.clearCart);

  Future<void> refreshCart() async {
    await _mutate(_repository.getCart);
  }

  Future<void> _mutate(Future<Cart> Function() operation) async {
    final previous = _mutationQueue;
    final mutation = previous == null
        ? _runMutation(operation)
        : previous.then((_) => _runMutation(operation));
    _mutationQueue = mutation;
    try {
      await mutation;
    } finally {
      if (identical(_mutationQueue, mutation)) _mutationQueue = null;
    }
  }

  Future<void> _runMutation(Future<Cart> Function() operation) async {
    final previous = state;
    state = const AsyncLoading<Cart>().copyWithPrevious(previous);
    try {
      state = AsyncData(await operation()).copyWithPrevious(previous);
    } catch (error, stackTrace) {
      state = AsyncError<Cart>(error, stackTrace).copyWithPrevious(previous);
    }
  }

  Future<void> _mutateProduct(
    int productId,
    Future<Cart> Function() operation,
  ) async {
    if (!_mutatingProducts.add(productId)) return;
    try {
      await _mutate(operation);
    } finally {
      _mutatingProducts.remove(productId);
    }
  }
}
