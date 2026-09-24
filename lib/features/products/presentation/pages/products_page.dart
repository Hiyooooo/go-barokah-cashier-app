import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_state_widgets.dart';
import '../../../cart/data/models/cart_models.dart';
import '../../../cart/presentation/pages/cart_page.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../data/models/product_models.dart';
import '../providers/product_provider.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final _searchController = TextEditingController();
  final _categoryIds = <int>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty || _categoryIds.isNotEmpty;

  Future<void> _search() => ref
      .read(productCatalogProvider.notifier)
      .applyFilters(
        query: _searchController.text,
        categoryIds: _categoryIds.toList(),
      );

  Future<void> _resetFilters() async {
    _searchController.clear();
    setState(_categoryIds.clear);
    await ref.read(productCatalogProvider.notifier).applyFilters();
  }

  Future<void> _toggleCategory(int categoryId) async {
    setState(() {
      if (!_categoryIds.remove(categoryId)) _categoryIds.add(categoryId);
    });
    await _search();
  }

  Future<void> _clearCategories() async {
    if (_categoryIds.isEmpty) return;
    setState(_categoryIds.clear);
    await _search();
  }

  Future<void> _refreshProducts() => ref.refresh(productCatalogProvider.future);

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productCatalogProvider);
    final categories = ref.watch(productCategoriesProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showPersistentCart =
              MediaQuery.orientationOf(context) == Orientation.landscape &&
              constraints.maxWidth >= 900;
          final browser = _ProductsBrowser(
            products: products,
            categories: categories,
            searchController: _searchController,
            selectedCategoryIds: _categoryIds,
            hasActiveFilters: _hasActiveFilters,
            onSearchChanged: (_) => setState(() {}),
            onSearchSubmitted: (_) => _search(),
            onSearch: _search,
            onRefresh: _refreshProducts,
            onRetry: () {
              unawaited(ref.refresh(productCatalogProvider.future));
            },
            onToggleCategory: _toggleCategory,
            onClearCategories: _clearCategories,
            onResetFilters: _resetFilters,
          );

          if (!showPersistentCart) return browser;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: browser),
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: AppColors.border,
              ),
              const SizedBox(width: 320, child: CartPanel()),
            ],
          );
        },
      ),
    );
  }
}

class _ProductsBrowser extends StatelessWidget {
  const _ProductsBrowser({
    required this.products,
    required this.categories,
    required this.searchController,
    required this.selectedCategoryIds,
    required this.hasActiveFilters,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onSearch,
    required this.onRefresh,
    required this.onRetry,
    required this.onToggleCategory,
    required this.onClearCategories,
    required this.onResetFilters,
  });

  final AsyncValue<ProductPage> products;
  final AsyncValue<List<ProductCategory>> categories;
  final TextEditingController searchController;
  final Set<int> selectedCategoryIds;
  final bool hasActiveFilters;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onSearch;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final ValueChanged<int> onToggleCategory;
  final VoidCallback onClearCategories;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= 720
            ? AppSpacing.xxxl
            : AppSpacing.lg;

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSpacing.lg,
              horizontalPadding,
              AppSpacing.xxxl,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Produk',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SearchField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        onSubmitted: onSearchSubmitted,
                        onSearch: onSearch,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      categories.when(
                        loading: () => const ClipRRect(
                          borderRadius: BorderRadius.all(
                            Radius.circular(AppRadius.badge),
                          ),
                          child: LinearProgressIndicator(minHeight: 3),
                        ),
                        error: (_, _) => const _CategoryUnavailable(),
                        data: (items) => _CategoryFilters(
                          categories: items,
                          selectedIds: selectedCategoryIds,
                          onToggle: onToggleCategory,
                          onShowAll: onClearCategories,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (products.isRefreshing) ...[
                        const ClipRRect(
                          borderRadius: BorderRadius.all(
                            Radius.circular(AppRadius.badge),
                          ),
                          child: LinearProgressIndicator(minHeight: 3),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      products.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(AppSpacing.section),
                          child: AppLoading(),
                        ),
                        error: (error, _) => AppError(
                          message: userFacingError(
                            error,
                            fallback: 'Produk belum dapat dimuat. Coba lagi.',
                          ),
                          onRetry: onRetry,
                        ),
                        data: (page) => _ProductResults(
                          page: page,
                          hasActiveFilters: hasActiveFilters,
                          onResetFilters: onResetFilters,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onSearch,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: 'Cari nama produk',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: IconButton(
        key: const ValueKey('search-products'),
        onPressed: onSearch,
        tooltip: 'Cari produk',
        icon: const Icon(Icons.arrow_forward),
      ),
    ),
  );
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({
    required this.categories,
    required this.selectedIds,
    required this.onToggle,
    required this.onShowAll,
  });

  final List<ProductCategory> categories;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('filter-categories'),
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: const Text('Semua'),
              selected: selectedIds.isEmpty,
              onSelected: (_) => onShowAll(),
            ),
          ),
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(category.name),
                selected: selectedIds.contains(category.id),
                onSelected: (_) => onToggle(category.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryUnavailable extends StatelessWidget {
  const _CategoryUnavailable();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(AppRadius.badge),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.info_outline, size: 18, color: AppColors.warmBrown),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            'Kategori tidak tersedia. Produk tetap dapat dicari.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.warmBrown),
          ),
        ),
      ],
    ),
  );
}

class _ProductResults extends ConsumerWidget {
  const _ProductResults({
    required this.page,
    required this.hasActiveFilters,
    required this.onResetFilters,
  });

  final ProductPage page;
  final bool hasActiveFilters;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (page.items.isEmpty) {
      return _ProductsEmpty(
        hasActiveFilters: hasActiveFilters,
        onResetFilters: onResetFilters,
      );
    }

    final total = page.meta?.total;
    final totalPages = page.meta?.totalPages ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (total != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              '$total produk ditemukan',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            const minCardWidth = 200.0;
            const gap = AppSpacing.lg;
            final columns =
                (constraints.maxWidth + gap) ~/ (minCardWidth + gap);
            final columnCount = columns.clamp(1, 4);
            final itemWidth =
                (constraints.maxWidth - (gap * (columnCount - 1))) /
                columnCount;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final product in page.items)
                  SizedBox(
                    width: itemWidth,
                    child: _ProductCard(product: product),
                  ),
              ],
            );
          },
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: AppSpacing.xxl),
          _Pagination(
            page: page,
            onPageChanged: (value) {
              ref.read(productCatalogProvider.notifier).goToPage(value);
            },
          ),
        ],
      ],
    );
  }
}

class _ProductsEmpty extends StatelessWidget {
  const _ProductsEmpty({
    required this.hasActiveFilters,
    required this.onResetFilters,
  });

  final bool hasActiveFilters;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.section),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.search_off, size: 40, color: AppColors.textMuted),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Produk tidak ditemukan',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          hasActiveFilters
              ? 'Coba ubah pencarian atau reset filter.'
              : 'Belum ada produk yang dapat ditampilkan.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        if (hasActiveFilters) ...[
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: onResetFilters,
            child: const Text('Reset filter'),
          ),
        ],
      ],
    ),
  );
}

class _Pagination extends StatelessWidget {
  const _Pagination({required this.page, required this.onPageChanged});

  final ProductPage page;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final current = page.meta!.page;
    final totalPages = page.meta!.totalPages;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton(
          onPressed: current > 1 ? () => onPageChanged(current - 1) : null,
          child: const Text('Sebelumnya'),
        ),
        Text(
          'Halaman $current dari $totalPages',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        OutlinedButton(
          onPressed: current < totalPages
              ? () => onPageChanged(current + 1)
              : null,
          child: const Text('Berikutnya'),
        ),
      ],
    );
  }
}

class _ProductCard extends ConsumerStatefulWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard> {
  bool _isAdding = false;

  Future<void> _addToCart() async {
    final cartNotifier = ref.read(cartProvider.notifier);
    if (_isAdding || cartNotifier.isMutatingProduct(widget.product.id)) return;

    setState(() => _isAdding = true);

    try {
      await cartNotifier.addItem(widget.product.id, quantity: 1);
      if (!mounted) return;

      final cartState = ref.read(cartProvider);
      final cart = cartState.valueOrNull;
      if (cartState.hasError) {
        _showCartFeedback(
          userFacingError(
            cartState.error!,
            fallback: 'Produk belum dapat ditambahkan ke keranjang.',
          ),
        );
        return;
      }
      final confirmedQuantity = cart == null
          ? null
          : _quantityForProduct(cart, widget.product.id);
      _showCartFeedback(
        confirmedQuantity == null
            ? '${widget.product.name} belum dapat ditambahkan.'
            : '${widget.product.name} ditambahkan. Jumlah terkonfirmasi: $confirmedQuantity.',
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  void _showCartFeedback(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          // ponytail: lifted above the sticky rail CTA + bottom nav, so
          // rapid quick-adds never block "Periksa pesanan". Revisit with a
          // proper toast/banner system only if feedback needs actions.
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final canAdd = product.isActive && product.stock > 0;
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final isAdding = _isAdding || cartNotifier.isMutatingProduct(product.id);
    final confirmedQuantity = _quantityForProduct(
      cartState.valueOrNull,
      product.id,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: canAdd,
            enabled: canAdd && !isAdding,
            label: canAdd
                ? 'Tambah satu ${product.name} ke keranjang'
                : 'Produk ${product.name} tidak tersedia',
            child: InkWell(
              key: ValueKey('quick-add-${product.id}'),
              onTap: canAdd && !isAdding ? _addToCart : null,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 2.6,
                      child: Stack(
                        children: [
                          _ProductImage(product: product),
                          if (confirmedQuantity != null)
                            Positioned(
                              top: AppSpacing.sm,
                              right: AppSpacing.sm,
                              child: _QuantityBadge(
                                quantity: confirmedQuantity,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (product.category case final category?)
                      Text(
                        category.name,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.warmBrown),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _ProductPrice(product: product),
                    const SizedBox(height: AppSpacing.sm),
                    _StockStatus(product: product),
                    if (canAdd) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(
                            isAdding
                                ? Icons.hourglass_top_outlined
                                : Icons.add_shopping_cart_outlined,
                            size: 18,
                            color: AppColors.forestGreen,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              isAdding
                                  ? 'Menambahkan 1...'
                                  : 'Ketuk untuk tambah 1 ke keranjang',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.forestGreen),
                            ),
                          ),
                          if (isAdding)
                            const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox.square(
                dimension: 48,
                child: IconButton(
                  key: ValueKey('product-detail-${product.id}'),
                  onPressed: () => context.push('/products/${product.id}'),
                  tooltip: 'Lihat detail ${product.name}',
                  icon: const Icon(Icons.info_outline),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityBadge extends StatelessWidget {
  const _QuantityBadge({required this.quantity});

  final int quantity;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Jumlah di keranjang: $quantity',
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.forestGreen),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_basket_outlined,
            size: 16,
            color: AppColors.forestGreen,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$quantity di keranjang',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.forestGreen),
          ),
        ],
      ),
    ),
  );
}

int? _quantityForProduct(Cart? cart, int productId) {
  for (final item in cart?.items ?? const <CartItem>[]) {
    if (item.productId == productId) return item.quantity;
  }
  return null;
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;
    final image = imageUrl == null || imageUrl.isEmpty
        ? const _ProductImagePlaceholder()
        : Image.network(
            _imageUrl(imageUrl),
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : const _ProductImagePlaceholder(),
            errorBuilder: (_, _, _) => const _ProductImagePlaceholder(),
          );

    return Semantics(
      image: true,
      label: 'Gambar ${product.name}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: SizedBox.expand(child: image),
      ),
    );
  }
}

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.canvas,
    child: Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 40,
        color: AppColors.sageGreen,
      ),
    ),
  );
}

class _ProductPrice extends StatelessWidget {
  const _ProductPrice({required this.product});

  final Product product;

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
        Text(
          formatPrice(finalPrice),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.forestGreen,
            fontWeight: FontWeight.w700,
          ),
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              Text(
                'Diskon ${product.discountAmount!.toStringAsFixed(0)}%',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.warmBrown),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StockStatus extends StatelessWidget {
  const _StockStatus({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final status = _status(product);
    return Semantics(
      label: 'Status stok: ${status.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: status.background,
          borderRadius: BorderRadius.circular(AppRadius.badge),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 17, color: status.foreground),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                status.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: status.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

_StockStatusData _status(Product product) {
  if (!product.isActive) {
    return const _StockStatusData(
      label: 'Tidak tersedia',
      icon: Icons.block_outlined,
      foreground: AppColors.textMuted,
      background: AppColors.borderSubtle,
    );
  }
  if (product.stock <= 0) {
    return const _StockStatusData(
      label: 'Stok habis',
      icon: Icons.remove_shopping_cart_outlined,
      foreground: AppColors.error,
      background: AppColors.errorContainer,
    );
  }
  if (product.criticalStock != null &&
      product.stock <= product.criticalStock!) {
    return _StockStatusData(
      label: 'Stok rendah: ${product.stock}',
      icon: Icons.warning_amber_outlined,
      foreground: AppColors.warmBrown,
      background: AppColors.warningContainer,
    );
  }
  return _StockStatusData(
    label: 'Tersedia: ${product.stock}',
    icon: Icons.check_circle_outline,
    foreground: AppColors.forestGreen,
    background: AppColors.successContainer,
  );
}

class _StockStatusData {
  const _StockStatusData({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
}

String _imageUrl(String value) =>
    Uri.parse(AppConfig.apiBaseUrl).resolve(value).toString();
