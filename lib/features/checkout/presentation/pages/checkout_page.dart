import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/checkout_models.dart';
import '../../../cart/data/models/cart_models.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/checkout_provider.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _cashController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  Future<void> _submit(Cart cart) async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(checkoutProvider.notifier)
        .submit(
          cartItemIds: cart.items.map((item) => item.id).toList(),
          cashReceived: num.parse(_cashController.text.trim()),
        );
    final result = ref.read(checkoutProvider);
    if (result.hasValue && result.valueOrNull != null) {
      ref.invalidate(cartProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final checkout = ref.watch(checkoutProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _Message(text: 'Unable to load cart.'),
        data: (value) => value.items.isEmpty
            ? const _Message(text: 'Your cart is empty.')
            : _CheckoutContent(
                cart: value,
                checkout: checkout,
                formKey: _formKey,
                cashController: _cashController,
                onSubmit: () => _submit(value),
              ),
      ),
    );
  }
}

class _CheckoutContent extends StatelessWidget {
  const _CheckoutContent({
    required this.cart,
    required this.checkout,
    required this.formKey,
    required this.cashController,
    required this.onSubmit,
  });

  final Cart cart;
  final AsyncValue<CashSaleResult?> checkout;
  final GlobalKey<FormState> formKey;
  final TextEditingController cashController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final result = checkout.valueOrNull;
    final isSubmitting = checkout.isLoading;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Items to sell', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...cart.items.map(
          (item) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.name),
            subtitle: Text('${item.quantity} x ${_price(item.finalPrice)}'),
            trailing: Text(_price(item.subtotal)),
          ),
        ),
        const Divider(),
        _SummaryRow(label: 'Subtotal', value: _price(cart.summary.subtotal)),
        _SummaryRow(
          label: 'Discount',
          value: _price(cart.summary.discountTotal),
        ),
        _SummaryRow(
          label: 'Total',
          value: _price(cart.summary.subtotal),
          emphasized: true,
        ),
        if (result == null) ...[
          const SizedBox(height: 24),
          Form(
            key: formKey,
            child: TextFormField(
              controller: cashController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cash received',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final cash = num.tryParse(value?.trim() ?? '');
                if (cash == null || cash < 0) {
                  return 'Enter a valid cash amount';
                }
                if (cash < cart.summary.subtotal) {
                  return 'Cash is less than the total';
                }
                return null;
              },
            ),
          ),
          if (checkout.hasError) ...[
            const SizedBox(height: 12),
            Text(
              checkout.error is ApiException
                  ? (checkout.error as ApiException).message
                  : 'Transaction failed. Please try again.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: isSubmitting ? null : onSubmit,
            child: Text(isSubmitting ? 'Processing...' : 'Complete cash sale'),
          ),
        ] else
          _SuccessResult(result: result),
      ],
    );
  }
}

class _SuccessResult extends StatelessWidget {
  const _SuccessResult({required this.result});

  final CashSaleResult result;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Transaction successful',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text('Sale number: ${result.saleNumber}'),
          Text('Grand total: ${_price(result.grandTotal)}'),
          Text('Cash received: ${_price(result.cashReceived)}'),
          Text('Change: ${_price(result.changeAmount)}'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.push('/receipt/${result.saleNumber}'),
            child: const Text('View receipt'),
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
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: emphasized ? Theme.of(context).textTheme.titleMedium : null,
        ),
        Text(
          value,
          style: emphasized ? Theme.of(context).textTheme.titleMedium : null,
        ),
      ],
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(child: Text(text));
}

String _price(num value) => 'Rp ${value.toStringAsFixed(0)}';
