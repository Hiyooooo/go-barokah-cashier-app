import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/async_state_widgets.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/utils/formatters.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
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
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: userFacingError(
            error,
            fallback: 'Unable to load product details. Please try again.',
          ),
          onRetry: () => ref.invalidate(productDetailProvider(productId)),
        ),
        data: (item) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (item.imageUrl?.isNotEmpty == true)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _imageUrl(item.imageUrl!),
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            if (item.imageUrl?.isNotEmpty == true) const SizedBox(height: 16),
            Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text('Price: ${formatPrice(item.price)}'),
            Text('Discount: ${item.discountAmount ?? 0}%'),
            Text('Final price: ${formatPrice(item.finalPrice ?? item.price)}'),
            Text('Stock: ${item.stock}'),
            if (item.category case final category?)
              Text('Category: ${category.name}'),
            if (item.minOrderQuantity case final minimum? when minimum > 1)
              Text('Minimum purchase: $minimum'),
            Text(item.isActive ? 'Available' : 'Not available'),
            if (item.isActive && item.stock > 0) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: ref.watch(cartProvider).isLoading
                    ? null
                    : () async {
                        await ref
                            .read(cartProvider.notifier)
                            .addItem(
                              item.id,
                              quantity: item.minOrderQuantity ?? 1,
                            );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.name} added to cart.'),
                          ),
                        );
                      },
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add to cart'),
              ),
            ],
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

String _imageUrl(String value) =>
    Uri.parse(AppConfig.apiBaseUrl).resolve(value).toString();
