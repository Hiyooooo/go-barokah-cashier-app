import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/async_state_widgets.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/receipt_models.dart';
import '../../printing/receipt_print_service.dart';
import '../providers/receipt_provider.dart';

class ReceiptPage extends ConsumerStatefulWidget {
  const ReceiptPage({required this.saleNumber, this.initialReceipt, super.key});

  final String saleNumber;
  final Receipt? initialReceipt;

  @override
  ConsumerState<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends ConsumerState<ReceiptPage> {
  final _printService = ReceiptPrintService();

  @override
  Widget build(BuildContext context) {
    final receipt = widget.initialReceipt != null
        ? AsyncValue.data(widget.initialReceipt!)
        : ref.watch(receiptProvider(widget.saleNumber));

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
              onPressed: () => _print(value),
            ),
          ),
        ],
      ),
      body: receipt.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: userFacingError(error, fallback: 'Unable to load receipt.'),
          onRetry: () => ref.invalidate(receiptProvider(widget.saleNumber)),
          onBack: () => context.pop(),
        ),
        data: (value) => _ReceiptPreview(
          receipt: value,
          onPrint: () => _print(value),
          onPreview: () =>
              context.push('/receipt/${widget.saleNumber}/print', extra: value),
        ),
      ),
    );
  }

  Future<void> _print(Receipt receipt) async {
    try {
      await _printService.print(receipt);
    } on ReceiptPrintException catch (error) {
      _showPrintError(error.message, receipt);
    } catch (_) {
      _showPrintError(
        'Printing failed. The transaction is still successful.',
        receipt,
      );
    }
  }

  void _showPrintError(String message, Receipt receipt) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Try again',
          onPressed: () => _print(receipt),
        ),
      ),
    );
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
      Text('Payment: ${receipt.paymentMethod.toUpperCase()}'),
      const Divider(height: 28),
      ...receipt.items.map(
        (item) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item.productName),
          subtitle: Text(
            '${item.quantity} x ${formatPrice(item.unitPrice)} '
            '→ ${formatPrice(item.finalUnitPrice)} '
            '(discount ${item.discountAmount}%)',
          ),
          trailing: Text(formatPrice(item.subtotal)),
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
      children: [Text(label), Text(formatPrice(value))],
    ),
  );
}
