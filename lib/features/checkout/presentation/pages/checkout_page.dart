import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/async_state_widgets.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/checkout_models.dart';
import '../../../cart/data/models/cart_models.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../receipt/data/models/receipt_models.dart';
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
    if (ref.read(checkoutProvider).valueOrNull != null) {
      ref.invalidate(cartProvider);
    }
  }

  Future<void> _openReceipt(CashSaleResult result) async {
    await context.push(
      '/receipt/${result.saleNumber}',
      extra: Receipt.fromCashSaleJson(result.toJson()),
    );
    if (mounted) {
      await ref.read(checkoutProvider.notifier).finalizeSale();
    }
  }

  Future<void> _openPrintPreview(CashSaleResult result) async {
    await context.push(
      '/receipt/${result.saleNumber}/print',
      extra: Receipt.fromCashSaleJson(result.toJson()),
    );
    if (mounted) {
      await ref.read(checkoutProvider.notifier).finalizeSale();
    }
  }

  Future<void> _startNewSale() async {
    await ref.read(checkoutProvider.notifier).resetCompletedSale();
    if (!mounted) return;
    context.go('/products');
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final checkout = ref.watch(checkoutProvider);
    final result = checkout.valueOrNull;
    final body = result != null
        ? _CheckoutSuccess(
            result: result,
            onOpenReceipt: _openReceipt,
            onPrintReceipt: _openPrintPreview,
            onNewSale: _startNewSale,
          )
        : cart.when(
            loading: () => const AppLoading(),
            error: (error, _) => AppError(
              message: userFacingError(
                error,
                fallback: 'Keranjang belum dapat dimuat.',
              ),
              onRetry: () => ref.invalidate(cartProvider),
            ),
            data: (value) => value.items.isEmpty
                ? _CheckoutEmpty(onBrowse: () => context.go('/products'))
                : _CheckoutContent(
                    cart: value,
                    checkout: checkout,
                    formKey: _formKey,
                    cashController: _cashController,
                    onSubmit: () => _submit(value),
                  ),
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: body,
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
    final isSubmitting = checkout.isLoading;
    final payment = _PaymentPanel(
      cart: cart,
      checkout: checkout,
      formKey: formKey,
      cashController: cashController,
      isSubmitting: isSubmitting,
      onSubmit: onSubmit,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 800;
        final items = _CartVerification(cart: cart);
        final content = isTablet
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 13, child: items),
                  const SizedBox(width: AppSpacing.xxl),
                  SizedBox(width: 340, child: payment),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  items,
                  const SizedBox(height: AppSpacing.xxl),
                  payment,
                ],
              );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: content,
            ),
          ),
        );
      },
    );
  }
}

class _CartVerification extends StatelessWidget {
  const _CartVerification({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Periksa pesanan',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'Pastikan produk dan jumlahnya sudah sesuai sebelum dibayar.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
      ),
      const SizedBox(height: AppSpacing.xxl),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              for (final item in cart.items) ...[
                _CartLine(item: item),
                if (item != cart.items.last)
                  const Divider(height: AppSpacing.xxl),
              ],
            ],
          ),
        ),
      ),
    ],
  );
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${item.quantity} x ${formatPrice(item.finalPrice)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      const SizedBox(width: AppSpacing.lg),
      Text(
        formatPrice(item.subtotal),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: AppColors.forestGreen),
      ),
    ],
  );
}

class _PaymentPanel extends StatelessWidget {
  const _PaymentPanel({
    required this.cart,
    required this.checkout,
    required this.formKey,
    required this.cashController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final Cart cart;
  final AsyncValue<CashSaleResult?> checkout;
  final GlobalKey<FormState> formKey;
  final TextEditingController cashController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: cashController,
        builder: (context, value, _) {
          final cash = num.tryParse(value.text.trim());
          final payable = cart.summary.subtotal;
          final changePreview = cash != null && cash >= payable
              ? cash - payable
              : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pembayaran tunai',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              _SummaryRow(label: 'Subtotal', value: formatPrice(payable)),
              _SummaryRow(
                label: 'Diskon',
                value: formatPrice(cart.summary.discountTotal),
              ),
              const Divider(height: AppSpacing.xxl),
              _SummaryRow(
                label: 'Jumlah yang harus dibayar',
                value: formatPrice(payable),
                emphasized: true,
              ),
              const SizedBox(height: AppSpacing.xl),
              Form(
                key: formKey,
                child: TextFormField(
                  controller: cashController,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onFieldSubmitted: (_) {
                    if (!isSubmitting) onSubmit();
                  },
                  decoration: const InputDecoration(
                    labelText: 'Uang diterima',
                    hintText: 'Masukkan nominal tunai',
                    prefixText: 'Rp ',
                  ),
                  validator: (value) {
                    final cash = num.tryParse(value?.trim() ?? '');
                    if (cash == null || cash < 0) {
                      return 'Masukkan nominal tunai yang valid.';
                    }
                    if (cash < payable) {
                      return 'Uang diterima kurang dari jumlah pembayaran.';
                    }
                    return null;
                  },
                ),
              ),
              if (changePreview != null) ...[
                const SizedBox(height: AppSpacing.md),
                _CheckoutNotice(
                  icon: Icons.calculate_outlined,
                  title: 'Estimasi kembalian',
                  message: formatPrice(changePreview),
                  color: AppColors.forestGreen,
                ),
              ],
              if (checkout.hasError) ...[
                const SizedBox(height: AppSpacing.md),
                _CheckoutError(error: checkout.error!),
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: isSubmitting ? null : onSubmit,
                child: Text(
                  isSubmitting
                      ? 'Mengirim transaksi...'
                      : 'Selesaikan transaksi',
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _CheckoutSuccess extends StatelessWidget {
  const _CheckoutSuccess({
    required this.result,
    required this.onOpenReceipt,
    required this.onPrintReceipt,
    required this.onNewSale,
  });

  final CashSaleResult result;
  final ValueChanged<CashSaleResult> onOpenReceipt;
  final ValueChanged<CashSaleResult> onPrintReceipt;
  final VoidCallback onNewSale;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.xxl),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          color: AppColors.successContainer,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.forestGreen,
                  size: 48,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Transaksi berhasil',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                _SummaryRow(label: 'Nomor transaksi', value: result.saleNumber),
                _SummaryRow(
                  label: 'Total',
                  value: formatPrice(result.grandTotal),
                ),
                _SummaryRow(
                  label: 'Uang diterima',
                  value: formatPrice(result.cashReceived),
                ),
                _SummaryRow(
                  label: 'Kembalian',
                  value: formatPrice(result.changeAmount),
                  emphasized: true,
                ),
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton(
                  onPressed: () => onOpenReceipt(result),
                  child: const Text('Lihat struk'),
                ),
                FilledButton.tonal(
                  onPressed: () => onPrintReceipt(result),
                  child: const Text('Cetak struk'),
                ),
                OutlinedButton(
                  onPressed: onNewSale,
                  child: const Text('Transaksi baru'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _CheckoutEmpty extends StatelessWidget {
  const _CheckoutEmpty({required this.onBrowse});

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
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: onBrowse, child: const Text('Lihat produk')),
        ],
      ),
    ),
  );
}

class _CheckoutError extends StatelessWidget {
  const _CheckoutError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final apiError = error is ApiException ? (error as ApiException) : null;
    final unknown =
        apiError != null &&
        (apiError.type == ApiErrorType.network ||
            apiError.type == ApiErrorType.timeout ||
            apiError.type == ApiErrorType.server);
    return _CheckoutNotice(
      icon: unknown ? Icons.help_outline : Icons.error_outline,
      title: unknown
          ? 'Status transaksi belum diketahui'
          : 'Transaksi belum berhasil',
      message: unknown
          ? 'Periksa koneksi lalu kirim ulang dengan nominal yang sama.'
          : userFacingError(error, fallback: 'Periksa data lalu coba lagi.'),
      color: unknown
          ? AppColors.warmBrown
          : Theme.of(context).colorScheme.error,
    );
  }
}

class _CheckoutNotice extends StatelessWidget {
  const _CheckoutNotice({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(AppRadius.badge),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(message),
            ],
          ),
        ),
      ],
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
