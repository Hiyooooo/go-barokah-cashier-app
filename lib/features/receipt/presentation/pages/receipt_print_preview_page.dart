import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../../core/widgets/async_state_widgets.dart';
import '../../printing/receipt_print_service.dart';
import '../providers/receipt_provider.dart';

class ReceiptPrintPreviewPage extends ConsumerWidget {
  const ReceiptPrintPreviewPage({required this.saleNumber, super.key});

  final String saleNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = ref.watch(receiptProvider(saleNumber));
    final service = ReceiptPrintService();

    return Scaffold(
      appBar: AppBar(title: const Text('Print preview')),
      body: receipt.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: userFacingError(error, fallback: 'Unable to load receipt.'),
          onRetry: () => ref.invalidate(receiptProvider(saleNumber)),
        ),
        data: (value) => PdfPreview(
          canChangePageFormat: false,
          canChangeOrientation: false,
          allowPrinting: true,
          allowSharing: true,
          build: (_) => service.buildPdf(value),
        ),
      ),
    );
  }
}
