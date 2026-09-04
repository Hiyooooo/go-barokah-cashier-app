import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/models/receipt_models.dart';

class ReceiptPrintService {
  Future<void> print(Receipt receipt) async {
    final info = await Printing.info();
    if (!info.canPrint) {
      throw const ReceiptPrintException(
        'No printer is available on this device.',
      );
    }

    final printed = await Printing.layoutPdf(
      name: 'Receipt-${receipt.saleNumber}.pdf',
      onLayout: (_) => buildPdf(receipt),
    );
    if (!printed) {
      throw const ReceiptPrintException('Printing was cancelled or failed.');
    }
  }

  Future<Uint8List> buildPdf(Receipt receipt) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat(
          80 * PdfPageFormat.mm,
          200 * PdfPageFormat.mm,
        ),
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
          pw.Text('Payment: ${receipt.paymentMethod}'),
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
    _row('${item.quantity} x ${_price(item.finalUnitPrice)}', item.subtotal),
  ];

  pw.Widget _row(String label, num value, {bool bold = false}) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(
        label,
        style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
      ),
      pw.Text(
        _price(value),
        style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
      ),
    ],
  );

  String _price(num value) => 'Rp ${value.toStringAsFixed(0)}';
}

class ReceiptPrintException implements Exception {
  const ReceiptPrintException(this.message);

  final String message;

  @override
  String toString() => message;
}
