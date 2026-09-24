import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_state_widgets.dart';
import '../../../cart/data/models/cart_models.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../data/models/product_models.dart';
import '../providers/product_provider.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({required this.productId, super.key});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail produk')),
      body: productState.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: _productDetailError(error),
          onRetry: () => ref.invalidate(productDetailProvider(productId)),
        ),
        data: (product) => _ProductDetailContent(product: product),
      ),
    );
  }
}

class _ProductDetailContent extends ConsumerStatefulWidget {
  const _ProductDetailContent({required this.product});

  final Product product;

  @override
  ConsumerState<_ProductDetailContent> createState() =>
      _ProductDetailContentState();
}

class _ProductDetailContentState extends ConsumerState<_ProductDetailContent> {
  bool _isAdding = false;
  String? _addErrorMessage;

  Future<void> _addToCart() async {
    final product = widget.product;
    final notifier = ref.read(cartProvider.notifier);
    if (_isAdding || notifier.isMutatingProduct(product.id)) return;

    setState(() {
      _isAdding = true;
      _addErrorMessage = null;
    });
    try {
      await notifier.addItem(product.id, quantity: 1);
      if (!mounted) return;

      final cartState = ref.read(cartProvider);
      if (cartState.hasError) {
        setState(() {
          _addErrorMessage = userFacingError(
            cartState.error!,
            fallback: 'Produk belum dapat ditambahkan ke keranjang.',
          );
        });
        return;
      }

      final confirmedQuantity = _cartQuantityFor(
        cartState.valueOrNull,
        product.id,
      );
      if (confirmedQuantity == null) {
        setState(() {
          _addErrorMessage =
              'Penambahan belum terkonfirmasi dari keranjang. Coba lagi.';
        });
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${product.name} ditambahkan. Jumlah di keranjang: $confirmedQuantity.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          ),
        );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    ref.watch(cartProvider);
    final isAdding =
        _isAdding ||
        ref.read(cartProvider.notifier).isMutatingProduct(product.id);
    final isAvailable = product.isActive && product.stock > 0;
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;

    final image = _ProductDetailImage(product: product);
    final facts = _ProductPurchaseFacts(
      product: product,
      isAvailable: isAvailable,
      isAdding: isAdding,
      cartErrorMessage: _addErrorMessage,
      onAdd: _addToCart,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth >= 700
            ? AppSpacing.xxxl
            : AppSpacing.lg;
        final useWideLayout = isTablet && constraints.maxWidth >= 680;
        final details = useWideLayout
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 11, child: image),
                  const SizedBox(width: AppSpacing.xxl),
                  Expanded(flex: 9, child: facts),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  image,
                  const SizedBox(height: AppSpacing.xl),
                  facts,
                ],
              );

        return ListView(
          padding: EdgeInsets.fromLTRB(
            padding,
            AppSpacing.lg,
            padding,
            AppSpacing.xxxl,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    details,
                    if (product.description?.trim().isNotEmpty == true) ...[
                      SizedBox(
                        height: isTablet ? AppSpacing.xxxl : AppSpacing.xxl,
                      ),
                      const Divider(),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Tentang produk',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        product.description!.trim(),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProductDetailImage extends StatelessWidget {
  const _ProductDetailImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;
    final image = imageUrl == null || imageUrl.isEmpty
        ? const _ProductImagePlaceholder()
        : Image.network(
            _imageUrl(imageUrl),
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : const _ProductImagePlaceholder(),
            errorBuilder: (_, _, _) => const _ProductImagePlaceholder(),
          );

    return Semantics(
      image: true,
      label: 'Gambar ${product.name}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.panel),
        child: AspectRatio(aspectRatio: 1.25, child: image),
      ),
    );
  }
}

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surface,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 40,
            color: AppColors.sageGreen,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Gambar produk tidak tersedia',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _ProductPurchaseFacts extends StatelessWidget {
  const _ProductPurchaseFacts({
    required this.product,
    required this.isAvailable,
    required this.isAdding,
    required this.cartErrorMessage,
    required this.onAdd,
  });

  final Product product;
  final bool isAvailable;
  final bool isAdding;
  final String? cartErrorMessage;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final finalPrice = product.finalPrice ?? product.price;
    final hasDiscount =
        product.discountAmount != null &&
        product.discountAmount! > 0 &&
        finalPrice < product.price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.category case final category?) ...[
          Text(
            category.name,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.warmBrown),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text(product.name, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.lg),
        Text(
          formatPrice(finalPrice),
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(color: AppColors.forestGreen),
        ),
        if (hasDiscount) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                formatPrice(product.price),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              Text(
                'Diskon ${product.discountAmount!.toStringAsFixed(0)}%',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.warmBrown),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        _ProductAvailability(product: product),
        const SizedBox(height: AppSpacing.lg),
        if (isAvailable)
          FilledButton.icon(
            onPressed: isAdding ? null : onAdd,
            icon: isAdding
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_shopping_cart_outlined),
            label: Text(
              isAdding ? 'Menambahkan 1...' : 'Tambah 1 ke keranjang',
            ),
          ),
        if (cartErrorMessage case final message?) ...[
          const SizedBox(height: AppSpacing.md),
          _InlineCartError(message: message),
        ],
        if (isAvailable && isAdding) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            liveRegion: true,
            child: Text(
              'Mengirim penambahan ke keranjang...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProductAvailability extends StatelessWidget {
  const _ProductAvailability({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final active = product.isActive;
    final inStock = product.stock > 0;
    final color = !active || !inStock
        ? Theme.of(context).colorScheme.error
        : AppColors.forestGreen;
    final icon = !active
        ? Icons.block_outlined
        : inStock
        ? Icons.inventory_2_outlined
        : Icons.remove_shopping_cart_outlined;
    final message = !active
        ? 'Produk tidak aktif'
        : inStock
        ? 'Stok tersedia: ${product.stock}'
        : 'Stok habis';

    return Semantics(
      label: 'Ketersediaan: $message',
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineCartError extends StatelessWidget {
  const _InlineCartError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    ),
  );
}

int? _cartQuantityFor(Cart? cart, int productId) {
  for (final item in cart?.items ?? const <CartItem>[]) {
    if (item.productId == productId) return item.quantity;
  }
  return null;
}

String _imageUrl(String value) =>
    Uri.parse(AppConfig.apiBaseUrl).resolve(value).toString();

String _productDetailError(Object error) =>
    error is ApiException && error.type == ApiErrorType.notFound
    ? 'Produk tidak ditemukan.'
    : userFacingError(error, fallback: 'Detail produk belum dapat dimuat.');
