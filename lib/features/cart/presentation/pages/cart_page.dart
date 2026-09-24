import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/widgets/async_state_widgets.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/cart_models.dart';
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

Future<bool> _confirmRemoveCartItem(
  BuildContext context,
  CartItem item,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Hapus produk dari keranjang?')),
            IconButton(
              onPressed: () => Navigator.pop(context, false),
              tooltip: 'Tutup konfirmasi',
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: Text('${item.name} akan dihapus dari keranjang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus produk'),
          ),
        ],
      ),
    ) ??
    false;

Future<void> _decrementCartItem(
  BuildContext context,
  WidgetRef ref,
  CartItem item,
) async {
  final notifier = ref.read(cartProvider.notifier);
  if (notifier.isMutatingProduct(item.productId)) return;

  if (item.quantity == 1) {
    if (!await _confirmRemoveCartItem(context, item) || !context.mounted) {
      return;
    }
    if (notifier.isMutatingProduct(item.productId)) return;

    final latestItem = _cartItemFor(ref, item.productId);
    if (latestItem == null) return;
    if (latestItem.quantity > 1) {
      await notifier.decrementItem(item.productId);
    } else {
      await notifier.removeItem(item.productId);
    }
    return;
  }

  await notifier.decrementItem(item.productId);
}

Future<void> _removeCartItem(
  BuildContext context,
  WidgetRef ref,
  CartItem item,
) async {
  final notifier = ref.read(cartProvider.notifier);
  if (notifier.isMutatingProduct(item.productId)) return;

  if (item.quantity == 1 && !await _confirmRemoveCartItem(context, item)) {
    return;
  }
  if (!context.mounted || notifier.isMutatingProduct(item.productId)) return;

  if (_cartItemFor(ref, item.productId) != null) {
    await notifier.removeItem(item.productId);
  }
}

CartItem? _cartItemFor(WidgetRef ref, int productId) => ref
    .read(cartProvider)
    .valueOrNull
    ?.items
    .where((item) => item.productId == productId)
    .firstOrNull;

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
    final mutationInProgress = cartState.isLoading;
    final notifier = ref.read(cartProvider.notifier);
    if (cart.items.isEmpty) {
      return Column(
        children: [
          if (cartState.hasError) ...[
            _CartMutationError(error: cartState.error!),
            const SizedBox(height: AppSpacing.md),
          ],
          Expanded(
            child: Center(
              child: _EmptyCart(onBrowse: () => context.go('/products')),
            ),
          ),
        ],
      );
    }

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
        if (mutationInProgress) ...[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: AppSpacing.md),
        ],
        if (cartState.hasError) ...[
          _CartMutationError(error: cartState.error!),
          const SizedBox(height: AppSpacing.md),
        ],
        Expanded(
          child: Scrollbar(
            child: ListView.separated(
              key: const ValueKey('cart-panel-list'),
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              itemCount: cart.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => _CartPanelItemRow(
                item: cart.items[index],
                disabled: notifier.isMutatingProduct(
                  cart.items[index].productId,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '${cart.summary.totalQuantity} barang • ${formatPrice(cart.summary.subtotal)}',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppColors.forestGreen),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          key: const ValueKey('review-cart'),
          onPressed: () => context.push('/order-review'),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Periksa pesanan'),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.onPressed,
    required this.tooltip,
    required this.icon,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final IconData icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: onPressed == null ? AppColors.borderSubtle : AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(AppRadius.badge),
    ),
    child: IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 18),
    ),
  );
}

class _CartPanelItemRow extends ConsumerStatefulWidget {
  const _CartPanelItemRow({required this.item, required this.disabled});

  final CartItem item;
  final bool disabled;

  @override
  ConsumerState<_CartPanelItemRow> createState() => _CartPanelItemRowState();
}

class _CartPanelItemRowState extends ConsumerState<_CartPanelItemRow> {
  bool _flashing = false;

  @override
  void didUpdateWidget(covariant _CartPanelItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Backend-confirmed increase only: the provider rebuilds this row with
    // the fresh cart after every successful mutation.
    if (widget.item.quantity > oldWidget.item.quantity) {
      HapticFeedback.lightImpact();
      setState(() => _flashing = true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _flashing = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final disabled = widget.disabled;
    final hasStockWarning = item.quantity >= item.stock;
    final stockColor = item.stock == 0
        ? Theme.of(context).colorScheme.error
        : hasStockWarning
        ? AppColors.warmBrown
        : AppColors.forestGreen;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: _flashing ? AppColors.successContainer : Colors.transparent,
        border: const Border(bottom: BorderSide(color: AppColors.borderSubtle)),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (_flashing)
                const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm),
                  child: Icon(
                    Icons.check_circle,
                    key: ValueKey('cart-flash'),
                    size: 20,
                    color: AppColors.forestGreen,
                  ),
                ),
              IconButton(
                onPressed: disabled
                    ? null
                    : () => _removeCartItem(context, ref, item),
                tooltip: 'Hapus ${item.name}',
                icon: const Icon(Icons.delete_outline, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              SizedBox.square(
                dimension: 44,
                child: _StepperButton(
                  onPressed: disabled
                      ? null
                      : () => _decrementCartItem(context, ref, item),
                  tooltip: item.quantity == 1
                      ? 'Hapus ${item.name}'
                      : 'Kurangi ${item.name}',
                  icon: Icons.remove,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Semantics(
                  label: 'Jumlah ${item.quantity}',
                  child: Text(
                    key: ValueKey('cart-quantity-${item.productId}'),
                    '${item.quantity}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              SizedBox.square(
                dimension: 44,
                child: _StepperButton(
                  onPressed: disabled || item.quantity >= item.stock
                      ? null
                      : () => ref
                            .read(cartProvider.notifier)
                            .addItem(item.productId),
                  tooltip: 'Tambah ${item.name}',
                  icon: Icons.add,
                ),
              ),
              const Spacer(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Subtotal',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      formatPrice(item.subtotal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                hasStockWarning
                    ? item.stock == 0
                          ? Icons.remove_shopping_cart_outlined
                          : Icons.warning_amber_outlined
                    : Icons.inventory_2_outlined,
                size: 16,
                color: stockColor,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  item.stock == 0
                      ? 'Stok habis'
                      : hasStockWarning
                      ? 'Stok ${item.stock} · batas tercapai'
                      : 'Stok ${item.stock}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: stockColor),
                ),
              ),
            ],
          ),
        ],
      ),
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
    final notifier = ref.read(cartProvider.notifier);
    final content = ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cart.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _CartItemTile(
        item: cart.items[index],
        disabled: notifier.isMutatingProduct(cart.items[index].productId),
      ),
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
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  key: const ValueKey('review-cart-screen'),
                  onPressed: mutationInProgress || cartState.hasError
                      ? null
                      : () => context.push('/order-review'),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Periksa pesanan'),
                ),
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
    final isMutating = notifier.isMutatingProduct(item.productId);
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
                  onPressed: isMutating
                      ? null
                      : () => _removeCartItem(context, ref, item),
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
                SizedBox.square(
                  dimension: 44,
                  child: _StepperButton(
                    onPressed: isMutating
                        ? null
                        : () => _decrementCartItem(context, ref, item),
                    tooltip: item.quantity == 1
                        ? 'Hapus ${item.name}'
                        : 'Kurangi ${item.name}',
                    icon: Icons.remove,
                  ),
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
                SizedBox.square(
                  dimension: 44,
                  child: _StepperButton(
                    onPressed: isMutating || item.quantity >= item.stock
                        ? null
                        : () => notifier.updateItem(
                            item.productId,
                            item.quantity + 1,
                          ),
                    tooltip: 'Tambah ${item.name}',
                    icon: Icons.add,
                  ),
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
