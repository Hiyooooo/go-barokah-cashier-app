import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/product_provider.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({required this.productId, super.key});

  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Product detail')),
      body: product.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Text(
            'Unable to load product details. Please try again.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        data: (item) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text('Price: ${_formatPrice(item.price)}'),
            Text('Discount: ${item.discountAmount ?? 0}%'),
            Text('Final price: ${_formatPrice(item.finalPrice ?? item.price)}'),
            Text('Stock: ${item.stock}'),
            Text(item.isActive ? 'Active' : 'Inactive'),
            if (item.description?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Text(item.description!),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatPrice(num value) => 'Rp ${value.toStringAsFixed(0)}';
