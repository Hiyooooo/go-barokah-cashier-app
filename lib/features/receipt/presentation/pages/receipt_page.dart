import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_state_widgets.dart';
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
  bool _isPrinting = false;
  bool _printFailed = false;
  String? _printMessage;

  @override
  Widget build(BuildContext context) {
    final receipt = widget.initialReceipt != null
        ? AsyncValue.data(widget.initialReceipt!)
        : ref.watch(receiptProvider(widget.saleNumber));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Struk transaksi'),
        actions: [
          if (receipt.valueOrNull case final value?)
            IconButton(
              tooltip: 'Cetak struk',
              icon: const Icon(Icons.print_outlined),
              onPressed: _isPrinting ? null : () => _print(value),
            ),
        ],
      ),
      body: receipt.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: userFacingError(
            error,
            fallback: 'Struk belum dapat dimuat.',
          ),
          onRetry: () => ref.invalidate(receiptProvider(widget.saleNumber)),
          onBack: () => context.pop(),
        ),
        data: (value) => _ReceiptContent(
          receipt: value,
          isPrinting: _isPrinting,
          printMessage: _printMessage,
          printFailed: _printFailed,
          onPrint: _isPrinting ? null : () => _print(value),
          onPreview: () =>
              context.push('/receipt/${widget.saleNumber}/print', extra: value),
        ),
      ),
    );
  }

  Future<void> _print(Receipt receipt) async {
    setState(() {
      _isPrinting = true;
      _printFailed = false;
      _printMessage = null;
    });

    try {
      await _printService.print(receipt);
      if (mounted) {
        setState(() => _printMessage = 'Struk berhasil dikirim ke printer.');
      }
    } on ReceiptPrintException catch (error) {
      if (mounted) {
        setState(() {
          _printMessage = error.message;
          _printFailed = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _printFailed = true;
          _printMessage =
              'Cetak struk gagal. Transaksi tetap berhasil dan dapat dicetak ulang.';
        });
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }
}

class _ReceiptContent extends StatelessWidget {
  const _ReceiptContent({
    required this.receipt,
    required this.isPrinting,
    required this.printMessage,
    required this.printFailed,
    required this.onPrint,
    required this.onPreview,
  });

  final Receipt receipt;
  final bool isPrinting;
  final String? printMessage;
  final bool printFailed;
  final VoidCallback? onPrint;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.xxl,
      AppSpacing.lg,
      AppSpacing.xxxl,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ReceiptHeader(receipt: receipt),
            const SizedBox(height: AppSpacing.lg),
            _ReceiptItems(receipt: receipt),
            const SizedBox(height: AppSpacing.lg),
            _ReceiptTotals(receipt: receipt),
            if (receipt.notes?.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.lg),
              _ReceiptSection(title: 'Catatan', child: Text(receipt.notes!)),
            ],
            if (printMessage != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _PrintNotice(message: printMessage!, isError: printFailed),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onPrint,
              icon: isPrinting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print_outlined),
              label: Text(
                isPrinting
                    ? 'Mencetak...'
                    : printFailed
                    ? 'Coba cetak lagi'
                    : 'Cetak struk',
              ),
            ),
            OutlinedButton.icon(
              onPressed: isPrinting ? null : onPreview,
              icon: const Icon(Icons.preview_outlined),
              label: const Text('Lihat pratinjau cetak'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ReceiptHeader extends StatelessWidget {
  const _ReceiptHeader({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Go-Barokah', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.lg),
          _ReceiptMeta(label: 'Nomor transaksi', value: receipt.saleNumber),
          _ReceiptMeta(
            label: 'Tanggal',
            value: formatDateTime(receipt.createdAt),
          ),
          _ReceiptMeta(label: 'Kasir', value: _orDash(receipt.cashierName)),
          _ReceiptMeta(
            label: 'Pembayaran',
            value: receipt.paymentMethod.toUpperCase(),
          ),
        ],
      ),
    ),
  );
}

class _ReceiptItems extends StatelessWidget {
  const _ReceiptItems({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) => _ReceiptSection(
    title: 'Item belanja',
    child: Column(
      children: [
        for (final item in receipt.items) ...[
          _ReceiptItem(item: item),
          if (item != receipt.items.last) const Divider(height: AppSpacing.xxl),
        ],
        if (receipt.items.isEmpty)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Tidak ada item pada struk.'),
          ),
      ],
    ),
  );
}

class _ReceiptItem extends StatelessWidget {
  const _ReceiptItem({required this.item});

  final ReceiptItem item;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(item.productName, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.xs),
      Text(
        '${item.quantity} x ${formatPrice(item.finalUnitPrice)}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      if (item.discountAmount > 0)
        Text(
          'Harga normal ${formatPrice(item.unitPrice)}. Diskon ${item.discountAmount}%.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      const SizedBox(height: AppSpacing.xs),
      Align(
        alignment: Alignment.centerRight,
        child: Text(
          formatPrice(item.subtotal),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppColors.forestGreen),
        ),
      ),
    ],
  );
}

class _ReceiptTotals extends StatelessWidget {
  const _ReceiptTotals({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) => _ReceiptSection(
    title: 'Ringkasan pembayaran',
    child: Column(
      children: [
        _ReceiptRow(label: 'Subtotal', value: receipt.subtotal),
        _ReceiptRow(label: 'Total diskon', value: receipt.discountTotal),
        const Divider(height: AppSpacing.xxl),
        _ReceiptRow(
          label: 'Total',
          value: receipt.grandTotal,
          emphasized: true,
        ),
        _ReceiptRow(label: 'Uang diterima', value: receipt.cashReceived),
        _ReceiptRow(label: 'Kembalian', value: receipt.changeAmount),
      ],
    ),
  );
}

class _ReceiptSection extends StatelessWidget {
  const _ReceiptSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    ),
  );
}

class _ReceiptMeta extends StatelessWidget {
  const _ReceiptMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final num value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: emphasized ? Theme.of(context).textTheme.titleMedium : null,
        ),
        Text(
          formatPrice(value),
          style: emphasized
              ? Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.forestGreen)
              : null,
        ),
      ],
    ),
  );
}

class _PrintNotice extends StatelessWidget {
  const _PrintNotice({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.forestGreen;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

String _orDash(String value) => value.trim().isEmpty ? '-' : value;
