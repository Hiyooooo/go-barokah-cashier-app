import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_state_widgets.dart';
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

  Future<void> _selectCategories(List<ProductCategory> categories) async {
    final selected = {..._categoryIds};
    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .75,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filter kategori',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Pilih satu atau beberapa kategori produk.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: categories.isEmpty
                        ? const Center(child: Text('Belum ada kategori.'))
                        : ListView(
                            children: [
                              for (final category in categories)
                                CheckboxListTile(
                                  value: selected.contains(category.id),
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(category.name),
                                  onChanged: (value) => setSheetState(() {
                                    if (value == true) {
                                      selected.add(category.id);
                                    } else {
                                      selected.remove(category.id);
                                    }
                                  }),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, {...selected}),
                    child: const Text('Terapkan filter'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _categoryIds
        ..clear()
        ..addAll(result);
    });
    await _search();
  }

  Future<void> _removeCategory(int categoryId) async {
    setState(() => _categoryIds.remove(categoryId));
    await _search();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productCatalogProvider);
    final categories = ref.watch(productCategoriesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(productCatalogProvider.future),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 720
                ? AppSpacing.xxxl
                : AppSpacing.lg;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.xxl,
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
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Pilih produk untuk memulai transaksi baru.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _SearchField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _search(),
                          onSearch: _search,
                        ),
                        const SizedBox(height: AppSpacing.md),
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
                            selectedIds: _categoryIds,
                            hasActiveFilters: _hasActiveFilters,
                            onSelect: () => _selectCategories(items),
                            onRemove: _removeCategory,
                            onReset: _resetFilters,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
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
                            onRetry: () {
                              unawaited(
                                ref.refresh(productCatalogProvider.future),
                              );
                            },
                          ),
                          data: (page) => _ProductResults(
                            page: page,
                            hasActiveFilters: _hasActiveFilters,
                            onResetFilters: _resetFilters,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final field = TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          labelText: 'Cari produk',
          hintText: 'Nama produk',
          prefixIcon: Icon(Icons.search),
        ),
      );
      final action = constraints.maxWidth < 420
          ? FilledButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.search),
              label: const Text('Cari produk'),
            )
          : IconButton.filled(
              onPressed: onSearch,
              tooltip: 'Cari produk',
              icon: const Icon(Icons.arrow_forward),
            );

      return constraints.maxWidth < 420
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                field,
                const SizedBox(height: AppSpacing.sm),
                action,
              ],
            )
          : Row(
              children: [
                Expanded(child: field),
                const SizedBox(width: AppSpacing.sm),
                action,
              ],
            );
    },
  );
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({
    required this.categories,
    required this.selectedIds,
    required this.hasActiveFilters,
    required this.onSelect,
    required this.onRemove,
    required this.onReset,
  });

  final List<ProductCategory> categories;
  final Set<int> selectedIds;
  final bool hasActiveFilters;
  final VoidCallback onSelect;
  final ValueChanged<int> onRemove;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final selectedCategories = categories
        .where((category) => selectedIds.contains(category.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.tune, size: 18, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Saring katalog',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: onSelect,
              label: Text(
                selectedIds.isEmpty
                    ? 'Semua kategori'
                    : '${selectedIds.length} kategori dipilih',
              ),
            ),
            if (hasActiveFilters)
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Reset filter'),
              ),
          ],
        ),
        if (selectedCategories.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final category in selectedCategories)
                InputChip(
                  label: Text(category.name),
                  onDeleted: () => onRemove(category.id),
                  deleteButtonTooltipMessage: 'Hapus ${category.name}',
                ),
            ],
          ),
        ],
      ],
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
            final columns = constraints.maxWidth >= 1080
                ? 3
                : constraints.maxWidth >= 680
                ? 2
                : 1;
            const gap = AppSpacing.lg;
            final itemWidth =
                (constraints.maxWidth - (gap * (columns - 1))) / columns;

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
    if (_isAdding) return;
    setState(() => _isAdding = true);

    try {
      await ref
          .read(cartProvider.notifier)
          .addItem(
            widget.product.id,
            quantity: widget.product.minOrderQuantity ?? 1,
          );
      if (!mounted) return;

      final cart = ref.read(cartProvider);
      final message = cart.hasError
          ? userFacingError(
              cart.error!,
              fallback: 'Produk belum dapat ditambahkan ke keranjang.',
            )
          : '${widget.product.name} ditambahkan ke keranjang.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final canAdd = product.isActive && product.stock > 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: 'Lihat detail produk ${product.name}',
            child: InkWell(
              onTap: () => context.push('/products/${product.id}'),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProductImage(product: product),
                    const SizedBox(height: AppSpacing.lg),
                    if (product.category case final category?)
                      Text(
                        category.name,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.warmBrown),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ProductPrice(product: product),
                    const SizedBox(height: AppSpacing.lg),
                    _StockStatus(product: product),
                    if (product.minOrderQuantity case final minimum?
                        when minimum > 1) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Minimum pembelian: $minimum',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: canAdd
                ? FilledButton.tonalIcon(
                    onPressed: _isAdding ? null : _addToCart,
                    icon: _isAdding
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_shopping_cart),
                    label: Text(
                      _isAdding ? 'Menambahkan...' : 'Tambah ke keranjang',
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.block_outlined),
                    label: const Text('Tidak tersedia'),
                  ),
          ),
        ],
      ),
    );
  }
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
            height: 150,
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
        child: SizedBox(height: 150, child: image),
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
