import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_state_widgets.dart';
import '../../../cart/data/models/cart_models.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/checkout_provider.dart';

class OrderReviewPage extends ConsumerWidget {
  const OrderReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final cart = cartState.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Periksa pesanan'),
        actions: [
          IconButton(
            tooltip: 'Segarkan keranjang',
            onPressed: cartState.isLoading
                ? null
                : () => ref.read(cartProvider.notifier).refreshCart(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: cart == null
          ? cartState.when(
              loading: () => const AppLoading(),
              error: (error, _) => AppError(
                message: userFacingError(
                  error,
                  fallback: 'Keranjang belum dapat dimuat.',
                ),
                onRetry: () => ref.invalidate(cartProvider),
              ),
              data: (_) => const SizedBox.shrink(),
            )
          : cart.items.isEmpty
          ? _EmptyReview(onBrowse: () => context.go('/products'))
          : _OrderReviewContent(
              cart: cart,
              isUpdating: cartState.isLoading,
              hasError: cartState.hasError,
              error: cartState.error,
              onRefresh: () => ref.read(cartProvider.notifier).refreshCart(),
              onRetry: () => ref.invalidate(cartProvider),
              onEdit: () => context.go('/cart'),
              onContinue: () async {
                await ref.read(checkoutProvider.notifier).resetCompletedSale();
                if (context.mounted) context.push('/checkout');
              },
            ),
    );
  }
}

class _OrderReviewContent extends StatelessWidget {
  const _OrderReviewContent({
    required this.cart,
    required this.isUpdating,
    required this.hasError,
    required this.error,
    required this.onRefresh,
    required this.onRetry,
    required this.onEdit,
    required this.onContinue,
  });

  final Cart cart;
  final bool isUpdating;
  final bool hasError;
  final Object? error;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final VoidCallback onEdit;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final isTablet = constraints.maxWidth >= 800;
      final continueButton = FilledButton.icon(
        key: const ValueKey('continue-to-checkout'),
        onPressed: isUpdating || hasError ? null : onContinue,
        icon: const Icon(Icons.payments_outlined),
        label: const Text('Lanjut ke pembayaran'),
      );
      final listScroll = RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CartReviewList(cart: cart),
              if (!isTablet) ...[
                const SizedBox(height: AppSpacing.lg),
                _CartReviewSummary(cart: cart),
              ],
            ],
          ),
        ),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daftar pesanan',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${cart.summary.itemsCount} jenis produk · ${cart.summary.totalQuantity} barang',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (isUpdating)
                      const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                    ),
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Ubah keranjang'),
                  ),
                ),
                if (hasError) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ReviewError(
                    message: userFacingError(
                      error!,
                      fallback: 'Perubahan keranjang belum tersimpan.',
                    ),
                    onRetry: onRetry,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: isTablet
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: listScroll),
                      const VerticalDivider(width: 1, thickness: 1),
                      SizedBox(
                        width: 320,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            AppSpacing.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  child: _CartReviewSummary(cart: cart),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              continueButton,
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : listScroll,
          ),
          if (!isTablet)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: continueButton,
              ),
            ),
        ],
      );
    },
  );
}

class _CartReviewList extends StatelessWidget {
  const _CartReviewList({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final item in cart.items) ...[
        _CartReviewItem(item: item),
        if (item != cart.items.last)
          const Divider(height: AppSpacing.lg, thickness: 1),
      ],
    ],
  );
}

class _CartReviewItem extends StatelessWidget {
  const _CartReviewItem({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = item.discountAmount != null && item.discountAmount! > 0;
    final stockUnavailable = item.stock == 0;
    final stockLimitReached = item.quantity >= item.stock;
    final stockColor = stockUnavailable
        ? AppColors.error
        : stockLimitReached
        ? AppColors.warmBrown
        : AppColors.forestGreen;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${item.quantity} × ${formatPrice(item.finalPrice)} per satuan',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (hasDiscount) ...[
                          Text(
                            'Normal ${formatPrice(item.price)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                ),
                          ),
                          Text(
                            'Diskon ${item.discountAmount!.toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.warmBrown),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          stockUnavailable
                              ? Icons.remove_shopping_cart_outlined
                              : stockLimitReached
                              ? Icons.warning_amber_outlined
                              : Icons.inventory_2_outlined,
                          size: 16,
                          color: stockColor,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            stockUnavailable
                                ? 'Stok habis'
                                : stockLimitReached
                                ? 'Stok ${item.stock}. Jumlah mencapai batas stok.'
                                : 'Stok tersedia: ${item.stock}',
                            maxLines: 1,
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
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Subtotal item',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
        ],
      ),
    );
  }
}

class _CartReviewSummary extends StatelessWidget {
  const _CartReviewSummary({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ringkasan pesanan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          _ReviewSummaryRow(
            label: 'Jumlah barang',
            value: '${cart.summary.totalQuantity}',
          ),
          _ReviewSummaryRow(
            label: 'Subtotal normal',
            value: formatPrice(cart.summary.normalSubtotal),
          ),
          _ReviewSummaryRow(
            label: 'Total diskon',
            value: formatPrice(cart.summary.discountTotal),
          ),
          const Divider(height: AppSpacing.xl),
          _ReviewSummaryRow(
            label: 'Subtotal setelah diskon',
            value: formatPrice(cart.summary.subtotal),
            emphasized: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nilai mengikuti keranjang terbaru dari server.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _ReviewSummaryRow extends StatelessWidget {
  const _ReviewSummaryRow({
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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

class _ReviewError extends StatelessWidget {
  const _ReviewError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.errorContainer,
      borderRadius: BorderRadius.circular(AppRadius.badge),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.error),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
        ),
        IconButton(
          onPressed: onRetry,
          tooltip: 'Coba sinkronkan keranjang lagi',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
  );
}

class _EmptyReview extends StatelessWidget {
  const _EmptyReview({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.remove_shopping_cart_outlined,
            size: 44,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Belum ada produk untuk diperiksa',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: onBrowse, child: const Text('Pilih produk')),
        ],
      ),
    ),
  );
}
