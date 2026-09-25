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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTabletLandscape = constraints.maxWidth >= 800;

        if (isTabletLandscape) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sisi Kiri: Virtual Receipt Canvas Paper (Scrollable)
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: SingleChildScrollView(
                        child: _ReceiptPaperCanvas(receipt: receipt),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xxl),
                // Sisi Kanan: Panel Aksi Sticky
                SizedBox(
                  width: 340,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Aksi Struk',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Transaksi ${receipt.saleNumber}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (printMessage != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            _PrintNotice(
                              message: printMessage!,
                              isError: printFailed,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          FilledButton.icon(
                            onPressed: onPrint,
                            icon: isPrinting
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
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
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton.icon(
                            onPressed: isPrinting ? null : onPreview,
                            icon: const Icon(Icons.preview_outlined),
                            label: const Text('Lihat pratinjau cetak'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextButton.icon(
                            onPressed: () => context.go('/products'),
                            icon: const Icon(Icons.storefront_outlined),
                            label: const Text('Transaksi baru'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile / Tablet Portrait
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ReceiptPaperCanvas(receipt: receipt),
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
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
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: isPrinting ? null : onPreview,
                    icon: const Icon(Icons.preview_outlined),
                    label: const Text('Lihat pratinjau cetak'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: () => context.go('/products'),
                    icon: const Icon(Icons.storefront_outlined),
                    label: const Text('Transaksi baru'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Kontainer Kertas Struk Tunggal (Receipt Paper Canvas)
class _ReceiptPaperCanvas extends StatelessWidget {
  const _ReceiptPaperCanvas({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Toko & Transaksi
          Center(
            child: Column(
              children: [
                Text(
                  'Go-Barokah',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Struk Pembayaran',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _DashedLine(),
          const SizedBox(height: AppSpacing.md),

          // Meta Info Transaksi
          _ReceiptMeta(label: 'Nomor transaksi', value: receipt.saleNumber),
          _ReceiptMeta(
            label: 'Tanggal',
            value: formatDateTime(receipt.createdAt),
          ),
          _ReceiptMeta(label: 'Kasir', value: _orDash(receipt.cashierName)),
          _ReceiptMeta(
            label: 'Metode Bayar',
            value: receipt.paymentMethod.toUpperCase(),
          ),
          const SizedBox(height: AppSpacing.md),
          const _DashedLine(),
          const SizedBox(height: AppSpacing.md),

          // Daftar Item Belanja
          Text(
            'Item Belanja',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final item in receipt.items) ...[
            _ReceiptItem(item: item),
            if (item != receipt.items.last)
              Divider(
                height: AppSpacing.md,
                thickness: 0.5,
                color: Colors.grey.shade300,
              ),
          ],
          if (receipt.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text('Tidak ada item pada struk.'),
            ),
          const SizedBox(height: AppSpacing.md),
          const _DashedLine(),
          const SizedBox(height: AppSpacing.md),

          // Ringkasan Pembayaran / Totals
          _ReceiptRow(label: 'Subtotal', value: receipt.subtotal),
          if (receipt.discountTotal > 0)
            _ReceiptRow(label: 'Total Diskon', value: receipt.discountTotal),
          const Divider(height: AppSpacing.lg, thickness: 1),
          _ReceiptRow(
            label: 'Total',
            value: receipt.grandTotal,
            emphasized: true,
          ),
          if (receipt.paymentMethod.toUpperCase() == 'CASH') ...[
            _ReceiptRow(label: 'Uang Diterima', value: receipt.cashReceived),
            _ReceiptRow(label: 'Kembalian', value: receipt.changeAmount),
          ],

          if (receipt.notes?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.md),
            const _DashedLine(),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Catatan:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              receipt.notes!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
          const _DashedLine(),
          const SizedBox(height: AppSpacing.md),

          // Ucapan Terima Kasih
          Center(
            child: Text(
              'Terima kasih atas kunjungan Anda!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Garis Putus-putus Khas Struk Thermal
class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        const dashSpace = 3.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ReceiptItem extends StatelessWidget {
  const _ReceiptItem({required this.item});

  final ReceiptItem item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.quantity} x ${formatPrice(item.finalUnitPrice)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
              if (item.discountAmount > 0)
                Text(
                  'Normal ${formatPrice(item.unitPrice)} (Diskon ${item.discountAmount}%)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          formatPrice(item.subtotal),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.forestGreen,
              ),
        ),
      ],
    ),
  );
}

class _ReceiptMeta extends StatelessWidget {
  const _ReceiptMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
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
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: emphasized
              ? Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
              : Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade800,
                  ),
        ),
        Text(
          formatPrice(value),
          style: emphasized
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.forestGreen,
                  )
              : Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
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
