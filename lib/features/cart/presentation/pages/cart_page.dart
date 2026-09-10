import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/async_state_widgets.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/cart_models.dart';
import '../../../checkout/presentation/providers/checkout_provider.dart';
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
                  : () => _confirmClear(context, ref),
              tooltip: 'Clear cart',
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: cart.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: userFacingError(
            error,
            fallback: 'Unable to load cart. Please try again.',
          ),
          onRetry: () => ref.invalidate(cartProvider),
        ),
        data: (value) => _CartContent(cart: value),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text('All items will be removed from the cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear cart'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(cartProvider.notifier).clearCart();
    }
  }
}

class _CartContent extends ConsumerWidget {
  const _CartContent({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cart.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your cart is empty.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/products'),
              child: const Text('Browse products'),
            ),
          ],
        ),
      );
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
                Text('Discount: ${formatPrice(cart.summary.discountTotal)}'),
                const SizedBox(height: 4),
                Text(
                  'Subtotal: ${formatPrice(cart.summary.subtotal)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () async {
            await ref.read(checkoutProvider.notifier).resetCompletedSale();
            if (context.mounted) context.push('/checkout');
          },
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
            Text('${formatPrice(item.finalPrice)} each | Stock: ${item.stock}'),
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
                Text(formatPrice(item.subtotal)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
