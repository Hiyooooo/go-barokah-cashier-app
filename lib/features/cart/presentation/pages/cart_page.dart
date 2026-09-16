import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
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

    final currentCart = cart.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        actions: [
          if (currentCart?.items.isNotEmpty == true)
            IconButton(
              onPressed: cart.isLoading
                  ? null
                  : () => _confirmClear(context, ref),
              tooltip: 'Kosongkan keranjang',
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
        ],
      ),
      body: currentCart != null
          ? _CartContent(cart: currentCart, cartState: cart)
          : cart.when(
              loading: () => const AppLoading(),
              error: (error, _) => AppError(
                message: userFacingError(
                  error,
                  fallback: 'Keranjang belum dapat dimuat.',
                ),
                onRetry: () => ref.invalidate(cartProvider),
              ),
              data: (value) => _CartContent(cart: value, cartState: cart),
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kosongkan keranjang?'),
        content: const Text('Semua produk akan dihapus dari keranjang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(cartProvider.notifier).clearCart();
    }
  }
}

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final cart = cartState.valueOrNull;

    Widget content;
    if (cart != null) {
      content = _CartPanelContent(cart: cart, cartState: cartState);
    } else {
      content = cartState.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: userFacingError(
            error,
            fallback: 'Keranjang belum dapat dimuat.',
          ),
          onRetry: () => ref.invalidate(cartProvider),
        ),
        data: (value) => _CartPanelContent(cart: value, cartState: cartState),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_basket_outlined,
                    size: 20,
                    color: AppColors.forestGreen,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Keranjang aktif',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          cart == null
                              ? 'Memuat isi keranjang'
                              : '${cart.summary.itemsCount} jenis produk',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

class _CartPanelContent extends ConsumerWidget {
  const _CartPanelContent({required this.cart, required this.cartState});

  final Cart cart;
  final AsyncValue<Cart> cartState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cart.items.isEmpty) {
      return _EmptyCart(onBrowse: () => context.go('/products'));
    }

    final mutationInProgress = cartState.isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cartState.isRefreshing) ...[
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.badge)),
            child: LinearProgressIndicator(minHeight: 3),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (cartState.hasError) ...[
          _CartMutationError(error: cartState.error!),
          const SizedBox(height: AppSpacing.md),
        ],
        Expanded(
          child: Scrollbar(
            child: ListView.separated(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              itemCount: cart.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => _CartItemTile(
                item: cart.items[index],
                disabled: mutationInProgress,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _CartSummary(cart: cart, disabled: mutationInProgress),
      ],
    );
  }
}

class _CartContent extends ConsumerWidget {
  const _CartContent({required this.cart, required this.cartState});

  final Cart cart;
  final AsyncValue<Cart> cartState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cart.items.isEmpty) {
      return _EmptyCart(onBrowse: () => context.go('/products'));
    }

    final mutationInProgress = cartState.isLoading;
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 800;
        final items = ListView.separated(
          shrinkWrap: true,
          physics: isTablet
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
          itemCount: cart.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) => _CartItemTile(
            item: cart.items[index],
            disabled: mutationInProgress,
          ),
        );
        final summary = _CartSummary(cart: cart, disabled: mutationInProgress);

        return isTablet
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 13, child: items),
                  const SizedBox(width: AppSpacing.xxl),
                  SizedBox(width: 320, child: summary),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  items,
                  const SizedBox(height: AppSpacing.xxl),
                  summary,
                ],
              );
      },
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(cartProvider.notifier).refreshCart(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Keranjang belanja',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${cart.summary.totalQuantity} barang dipilih',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                if (cartState.hasError) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _CartMutationError(error: cartState.error!),
                ],
                const SizedBox(height: AppSpacing.xxl),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  const _CartItemTile({required this.item, required this.disabled});

  final CartItem item;
  final bool disabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    final hasDiscount = item.discountAmount != null && item.discountAmount! > 0;
    final stockWarning = item.quantity >= item.stock;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: disabled
                      ? null
                      : () => notifier.removeItem(item.productId),
                  tooltip: 'Hapus ${item.name}',
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  formatPrice(item.finalPrice),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (hasDiscount) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    formatPrice(item.price),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Diskon ${item.discountAmount!.toStringAsFixed(0)}%',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.warmBrown),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Stok tersedia: ${item.stock}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (stockWarning) ...[
              const SizedBox(height: AppSpacing.sm),
              _CartNotice(
                icon: Icons.warning_amber_outlined,
                message: item.stock == 0
                    ? 'Produk ini tidak tersedia.'
                    : 'Jumlah sudah mencapai stok tersedia.',
                color: item.stock == 0 ? AppColors.error : AppColors.warmBrown,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                IconButton(
                  onPressed: disabled || item.quantity <= 1
                      ? null
                      : () => notifier.updateItem(
                          item.productId,
                          item.quantity - 1,
                        ),
                  icon: const Icon(Icons.remove),
                ),
                Semantics(
                  label: 'Jumlah ${item.quantity}',
                  child: SizedBox(
                    width: 40,
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: disabled || item.quantity >= item.stock
                      ? null
                      : () => notifier.updateItem(
                          item.productId,
                          item.quantity + 1,
                        ),
                  icon: const Icon(Icons.add),
                ),
                const Spacer(),
                Text(
                  formatPrice(item.subtotal),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.forestGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSummary extends ConsumerWidget {
  const _CartSummary({required this.cart, required this.disabled});

  final Cart cart;
  final bool disabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ringkasan belanja',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SummaryRow(
            label: 'Jumlah barang',
            value: '${cart.summary.totalQuantity}',
          ),
          _SummaryRow(
            label: 'Total normal',
            value: formatPrice(cart.summary.normalSubtotal),
          ),
          _SummaryRow(
            label: 'Diskon',
            value: formatPrice(cart.summary.discountTotal),
          ),
          const Divider(height: AppSpacing.xxl),
          _SummaryRow(
            label: 'Subtotal',
            value: formatPrice(cart.summary.subtotal),
            emphasized: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: disabled
                ? null
                : () async {
                    await ref
                        .read(checkoutProvider.notifier)
                        .resetCompletedSale();
                    if (context.mounted) context.push('/checkout');
                  },
            child: Text(disabled ? 'Memperbarui...' : 'Lanjut ke checkout'),
          ),
        ],
      ),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: emphasized ? Theme.of(context).textTheme.titleMedium : null,
        ),
        Text(
          value,
          style: emphasized
              ? Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.forestGreen)
              : null,
        ),
      ],
    ),
  );
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Keranjang masih kosong',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tambahkan produk sebelum melanjutkan ke checkout.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: onBrowse, child: const Text('Lihat produk')),
        ],
      ),
    ),
  );
}

class _CartMutationError extends StatelessWidget {
  const _CartMutationError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => _CartNotice(
    icon: Icons.error_outline,
    message: userFacingError(
      error,
      fallback: 'Perubahan keranjang belum tersimpan.',
    ),
    color: Theme.of(context).colorScheme.error,
  );
}

class _CartNotice extends StatelessWidget {
  const _CartNotice({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(AppRadius.badge),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(message, style: TextStyle(color: color)),
        ),
      ],
    ),
  );
}
