import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Unable to load receipt.')),
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
