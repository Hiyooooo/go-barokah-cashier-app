import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/cart_models.dart';
import '../providers/cart_provider.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (cart.valueOrNull?.items.isNotEmpty == true)
            IconButton(
              onPressed: cart.isLoading
                  ? null
                  : () => ref.read(cartProvider.notifier).clearCart(),
              tooltip: 'Clear cart',
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: cart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _CartMessage(
          message: 'Unable to load cart. Please try again.',
        ),
        data: (value) => _CartContent(cart: value),
      ),
    );
  }
}

class _CartContent extends ConsumerWidget {
  const _CartContent({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cart.items.isEmpty) {
      return const _CartMessage(message: 'Your cart is empty.');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...cart.items.map((item) => _CartItemTile(item: item)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Items: ${cart.summary.totalQuantity}'),
                Text('Discount: ${_price(cart.summary.discountTotal)}'),
                const SizedBox(height: 4),
                Text(
                  'Subtotal: ${_price(cart.summary.subtotal)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => context.push('/checkout'),
          child: const Text('Proceed to checkout'),
        ),
      ],
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  const _CartItemTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(cartProvider).isLoading;
    final notifier = ref.read(cartProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.name)),
                IconButton(
                  onPressed: loading
                      ? null
                      : () => notifier.removeItem(item.productId),
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            Text('${_price(item.finalPrice)} each | Stock: ${item.stock}'),
            Row(
              children: [
                IconButton(
                  onPressed: loading || item.quantity <= 1
                      ? null
                      : () => notifier.updateItem(
                          item.productId,
                          item.quantity - 1,
                        ),
                  icon: const Icon(Icons.remove),
                ),
                Text('${item.quantity}'),
                IconButton(
                  onPressed: loading || item.quantity >= item.stock
                      ? null
                      : () => notifier.updateItem(
                          item.productId,
                          item.quantity + 1,
                        ),
                  icon: const Icon(Icons.add),
                ),
                const Spacer(),
                Text(_price(item.subtotal)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartMessage extends StatelessWidget {
  const _CartMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}

String _price(num value) => 'Rp ${value.toStringAsFixed(0)}';
