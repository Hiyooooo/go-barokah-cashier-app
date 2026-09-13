import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/utils/formatters.dart';

import '../data/models/receipt_models.dart';

class ReceiptPrintService {
  static const receiptPageFormat = PdfPageFormat(
    80 * PdfPageFormat.mm,
    200 * PdfPageFormat.mm,
  );

  Future<void> print(Receipt receipt) async {
    final startedAt = DateTime.now();
    var layoutCalls = 0;
    _log(
      'START sale=${receipt.saleNumber} items=${receipt.items.length} '
      'format=${receiptPageFormat.width}x${receiptPageFormat.height} '
      'dynamicLayout=false',
    );

    try {
      final info = await Printing.info();
      _log(
        'INFO canPrint=${info.canPrint} directPrint=${info.directPrint} '
        'canListPrinters=${info.canListPrinters} dynamicLayout=${info.dynamicLayout} '
        'canShare=${info.canShare}',
      );

      if (!info.canPrint) {
        throw const ReceiptPrintException(
          'No printer is available on this device.',
        );
      }

      // Build before opening the platform dialog. The callback then returns
      // stable bytes even if the Android print service changes configuration.
      final pdfStartedAt = DateTime.now();
      final pdf = await buildPdf(receipt);
      _log(
        'PDF_READY bytes=${pdf.length} elapsedMs=${DateTime.now().difference(pdfStartedAt).inMilliseconds}',
      );

      _log('LAYOUT_OPEN');
      final printed = await Printing.layoutPdf(
        format: receiptPageFormat,
        dynamicLayout: false,
        name: 'Receipt-${receipt.saleNumber}.pdf',
        onLayout: (_) async {
          layoutCalls++;
          _log('LAYOUT_CALLBACK count=$layoutCalls bytes=${pdf.length}');
          return pdf;
        },
      );
      _log(
        'LAYOUT_RESULT printed=$printed callbacks=$layoutCalls '
        'elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds}',
      );
      if (!printed) {
        throw const ReceiptPrintException('Printing was cancelled or failed.');
      }
      _log('SUCCESS sale=${receipt.saleNumber}');
    } catch (error, stackTrace) {
      _logError(
        'FAIL sale=${receipt.saleNumber} type=${error.runtimeType} '
        'callbacks=$layoutCalls elapsedMs=${DateTime.now().difference(startedAt).inMilliseconds}',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<Uint8List> buildPdf(Receipt receipt) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: receiptPageFormat,
        margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        build: (_) => [
          pw.Center(
            child: pw.Text(
              'GO-BAROKAH',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Sale: ${receipt.saleNumber}'),
          pw.Text('Date: ${receipt.createdAt?.toLocal() ?? '-'}'),
          pw.Text('Cashier: ${receipt.cashierName}'),
          pw.Text('Payment: ${receipt.paymentMethod.toUpperCase()}'),
          pw.Divider(),
          ...receipt.items.expand(_itemRows),
          pw.Divider(),
          _row('Subtotal', receipt.subtotal),
          _row('Discount', receipt.discountTotal),
          _row('GRAND TOTAL', receipt.grandTotal, bold: true),
          _row('Cash received', receipt.cashReceived),
          _row('Change', receipt.changeAmount),
          if (receipt.notes?.isNotEmpty == true) ...[
            pw.SizedBox(height: 6),
            pw.Text('Notes: ${receipt.notes}'),
          ],
        ],
      ),
    );
    return document.save();
  }

  Iterable<pw.Widget> _itemRows(ReceiptItem item) => [
    pw.Text(item.productName),
    _row(
      '${item.quantity} x ${formatPrice(item.finalUnitPrice)}',
      item.subtotal,
    ),
  ];

  pw.Widget _row(String label, num value, {bool bold = false}) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        label,
        style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
      ),
      pw.Text(
        formatPrice(value),
        style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
      ),
    ],
  );

  void _log(String message) {
    const linePrefix = '[GO_BAROKAH_PRINT]';
    debugPrint('$linePrefix $message');
    developer.log(message, name: 'go_barokah.print');
  }

  void _logError(String message, Object error, StackTrace stackTrace) {
    const linePrefix = '[GO_BAROKAH_PRINT_ERROR]';
    debugPrint('$linePrefix $message error=$error');
    developer.log(
      message,
      name: 'go_barokah.print',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

class ReceiptPrintException implements Exception {
  const ReceiptPrintException(this.message);

  final String message;

  @override
  String toString() => message;
}
