import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/async_state_widgets.dart';
import '../../../../core/utils/formatters.dart';
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

  Future<void> _search() => ref
      .read(productCatalogProvider.notifier)
      .applyFilters(
        query: _searchController.text,
        categoryIds: _categoryIds.toList(),
      );

  Future<void> _selectCategories(List<ProductCategory> categories) async {
    final selected = {..._categoryIds};
    final applied = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Filter categories')),
              ...categories.map(
                (category) => CheckboxListTile(
                  value: selected.contains(category.id),
                  title: Text(category.name),
                  onChanged: (value) => setSheetState(() {
                    if (value == true) {
                      selected.add(category.id);
                    } else {
                      selected.remove(category.id);
                    }
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Apply filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (applied == true && mounted) {
      setState(() {
        _categoryIds
          ..clear()
          ..addAll(selected);
      });
      await _search();
    }
  }

  Future<void> _resetFilters() async {
    _searchController.clear();
    setState(_categoryIds.clear);
    await ref.read(productCatalogProvider.notifier).applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productCatalogProvider);
    final categories = ref.watch(productCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(productCatalogProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      labelText: 'Search products',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _search,
                  tooltip: 'Search',
                  icon: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
            const SizedBox(height: 12),
            categories.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Categories are unavailable.'),
              data: (items) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _selectCategories(items),
                    icon: const Icon(Icons.filter_list),
                    label: Text(
                      _categoryIds.isEmpty
                          ? 'All categories'
                          : '${_categoryIds.length} categories selected',
                    ),
                  ),
                  if (_categoryIds.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: items
                          .where((item) => _categoryIds.contains(item.id))
                          .map((item) => Chip(label: Text(item.name)))
                          .toList(),
                    ),
                  if (_categoryIds.isNotEmpty ||
                      _searchController.text.trim().isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _resetFilters,
                        child: const Text('Reset filters'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            products.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: AppLoading(),
              ),
              error: (error, _) => AppError(
                message: userFacingError(
                  error,
                  fallback: 'Unable to load products. Please try again.',
                ),
              ),
              data: (page) => _ProductResults(page: page),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductResults extends ConsumerWidget {
  const _ProductResults({required this.page});

  final ProductPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    if (page.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: AppEmpty(message: 'No products found.'),
      );
    }

    final totalPages = page.meta?.totalPages ?? 1;
    return Column(
      children: [
        if (page.meta != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text('${page.meta!.total} products found'),
          ),
        ...page.items.map(
          (product) => Card(
            child: Column(
              children: [
                ListTile(
                  enabled: product.isActive,
                  onTap: () => context.push('/products/${product.id}'),
                  title: Text(product.name),
                  subtitle: Text(
                    product.isActive
                        ? '${_stockLabel(product.stock, product.criticalStock)}${product.minOrderQuantity != null && product.minOrderQuantity! > 1 ? ' · Min: ${product.minOrderQuantity}' : ''}'
                        : 'Not available',
                  ),
                  trailing: Text(
                    formatPrice(product.finalPrice ?? product.price),
                  ),
                ),
                if (product.isActive && product.stock > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: FilledButton.tonalIcon(
                      onPressed: cartState.isLoading
                          ? null
                          : () async {
                              await ref
                                  .read(cartProvider.notifier)
                                  .addItem(
                                    product.id,
                                    quantity: product.minOrderQuantity ?? 1,
                                  );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ref.read(cartProvider).hasError
                                        ? 'Unable to add ${product.name} to cart.'
                                        : '${product.name} added to cart.',
                                  ),
                                ),
                              );
                            },
                      icon: cartState.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_shopping_cart),
                      label: Text(
                        cartState.isLoading ? 'Adding...' : 'Add to cart',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (totalPages > 1) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: page.meta!.page > 1
                    ? () => ref
                          .read(productCatalogProvider.notifier)
                          .goToPage(page.meta!.page - 1)
                    : null,
                child: const Text('Previous'),
              ),
              Text('Page ${page.meta!.page} of $totalPages'),
              OutlinedButton(
                onPressed: page.meta!.page < totalPages
                    ? () => ref
                          .read(productCatalogProvider.notifier)
                          .goToPage(page.meta!.page + 1)
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

String _stockLabel(int stock, int? criticalStock) {
  if (stock <= 0) return 'Out of stock';
  if (criticalStock != null && stock <= criticalStock) {
    return 'Low stock: $stock';
  }
  return 'In stock: $stock';
}
