import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/async_state_widgets.dart';
import '../../printing/receipt_print_service.dart';
import '../providers/receipt_provider.dart';
import '../../data/models/receipt_models.dart';

class ReceiptPage extends ConsumerWidget {
  const ReceiptPage({required this.saleNumber, super.key});

  final String saleNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = ref.watch(receiptProvider(saleNumber));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        actions: [
          receipt.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (value) => IconButton(
              tooltip: 'Print receipt',
              icon: const Icon(Icons.print_outlined),
              onPressed: () => _print(context, value),
            ),
          ),
        ],
      ),
      body: receipt.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: userFacingError(error, fallback: 'Unable to load receipt.'),
          onRetry: () => ref.invalidate(receiptProvider(saleNumber)),
        ),
        data: (value) => _ReceiptPreview(
          receipt: value,
          onPrint: () => _print(context, value),
          onPreview: () => context.push('/receipt/$saleNumber/print'),
        ),
      ),
    );
  }

  Future<void> _print(BuildContext context, Receipt receipt) async {
    try {
      await ReceiptPrintService().print(receipt);
    } on ReceiptPrintException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Printing failed. The transaction is still successful.',
            ),
          ),
        );
      }
    }
  }
}

class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({
    required this.receipt,
    required this.onPrint,
    required this.onPreview,
  });

  final Receipt receipt;
  final VoidCallback onPrint;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text('Go-Barokah', style: Theme.of(context).textTheme.headlineSmall),
      Text('Sale number: ${receipt.saleNumber}'),
      Text('Date: ${receipt.createdAt?.toLocal() ?? '-'}'),
      Text('Cashier: ${receipt.cashierName}'),
      Text('Payment: ${receipt.paymentMethod}'),
      const Divider(height: 28),
      ...receipt.items.map(
        (item) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item.productName),
          subtitle: Text(
            '${item.quantity} x ${_price(item.finalUnitPrice)} '
            '(discount ${item.discountAmount}%)',
          ),
          trailing: Text(_price(item.subtotal)),
        ),
      ),
      const Divider(height: 28),
      _ReceiptRow(label: 'Subtotal', value: receipt.subtotal),
      _ReceiptRow(label: 'Total discount', value: receipt.discountTotal),
      _ReceiptRow(label: 'Grand total', value: receipt.grandTotal),
      _ReceiptRow(label: 'Cash received', value: receipt.cashReceived),
      _ReceiptRow(label: 'Change', value: receipt.changeAmount),
      if (receipt.notes?.isNotEmpty == true) ...[
        const SizedBox(height: 16),
        Text('Notes: ${receipt.notes}'),
      ],
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: onPrint,
        icon: const Icon(Icons.print),
        label: const Text('Print receipt'),
      ),
      OutlinedButton.icon(
        onPressed: onPreview,
        icon: const Icon(Icons.preview),
        label: const Text('Open print preview'),
      ),
    ],
  );
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final num value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text(_price(value))],
    ),
  );
}

String _price(num value) => 'Rp ${value.toStringAsFixed(0)}';
