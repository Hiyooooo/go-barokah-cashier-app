import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  int? _categoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() => ref
      .read(productCatalogProvider.notifier)
      .applyFilters(query: _searchController.text, categoryId: _categoryId);

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
              data: (items) => DropdownButtonFormField<int?>(
                initialValue: _categoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All categories'),
                  ),
                  ...items.map(
                    (category) => DropdownMenuItem<int?>(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _categoryId = value);
                  _search();
                },
              ),
            ),
            const SizedBox(height: 16),
            products.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const _ErrorMessage(
                message: 'Unable to load products. Please try again.',
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
    if (page.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No products found.')),
      );
    }

    final totalPages = page.meta?.totalPages ?? 1;
    return Column(
      children: [
        ...page.items.map(
          (product) => Card(
            child: Column(
              children: [
                ListTile(
                  enabled: product.isActive,
                  onTap: () => context.push('/products/${product.id}'),
                  title: Text(product.name),
                  subtitle: Text(
                    product.isActive ? 'Stock: ${product.stock}' : 'Inactive',
                  ),
                  trailing: Text(_price(product.finalPrice ?? product.price)),
                ),
                if (product.isActive && product.stock > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        await ref
                            .read(cartProvider.notifier)
                            .addItem(product.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ref.read(cartProvider).hasError
                                  ? 'Unable to add product to cart.'
                                  : 'Added to cart.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add to cart'),
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

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}

String _price(num value) => 'Rp ${value.toStringAsFixed(0)}';
