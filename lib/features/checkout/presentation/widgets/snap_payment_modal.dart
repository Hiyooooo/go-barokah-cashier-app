import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/checkout_models.dart';
import '../providers/checkout_provider.dart';

class SnapPaymentModal extends ConsumerStatefulWidget {
  const SnapPaymentModal({
    required this.saleResult,
    this.controller,
    this.onCancel,
    super.key,
  });

  final CashSaleResult saleResult;
  final WebViewController? controller;
  final Future<void> Function()? onCancel;

  static Future<void> show(BuildContext context, CashSaleResult saleResult) =>
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => SnapPaymentModal(saleResult: saleResult),
      );

  @override
  ConsumerState<SnapPaymentModal> createState() => _SnapPaymentModalState();
}

class _SnapPaymentModalState extends ConsumerState<SnapPaymentModal> {
  WebViewController? _controller;
  var _isCancelling = false;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  bool _hasExpiry = false;

  bool get _isQris => widget.saleResult.paymentMethod == 'QRIS';

  @override
  void initState() {
    super.initState();
    // ponytail: WebView only for non-QRIS (VA keeps Snap); QRIS renders offline via qr_flutter.
    if (!_isQris) {
      if (widget.controller != null) {
        _controller = widget.controller;
      } else if (widget.saleResult.paymentUrl != null) {
        try {
          _controller = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(Uri.parse(widget.saleResult.paymentUrl!));
        } catch (_) {
          // Fallback gracefully in test/mock environment where WebViewPlatform is not bound.
        }
      }
    }
    final expiry = widget.saleResult.expiryTime;
    if (_isQris && expiry != null) {
      _hasExpiry = true;
      _remaining = expiry.difference(DateTime.now());
      // ponytail: 1s ticker for countdown display only; polling stays on the provider timer.
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _remaining = expiry.difference(DateTime.now());
        });
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan pembayaran?'),
        content: const Text(
          'Pelanggan tidak akan dapat membayar tagihan ini lagi dan stok produk akan dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _cancelAndClose();
    }
  }

  Future<void> _cancelAndClose() async {
    setState(() => _isCancelling = true);
    if (widget.onCancel != null) {
      await widget.onCancel!();
    } else {
      await ref.read(checkoutProvider.notifier).cancelPendingSale();
    }
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auto-dismiss when status changes from PENDING to COMPLETED or Error
    ref.listen<AsyncValue<CashSaleResult?>>(checkoutProvider, (_, next) {
      final value = next.valueOrNull;
      if (value != null && value.status == 'COMPLETED') {
        Navigator.of(context, rootNavigator: true).pop();
      } else if (next.hasError) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });

    final methodLabel = _isQris ? 'QRIS' : 'Virtual Account';

    return AlertDialog(
      title: Row(
        children: [
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Menunggu Pembayaran $methodLabel'),
                Text(
                  'No. ${widget.saleResult.saleNumber}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isQris ? _buildQrisContent(context) : _buildVaContent(),
      ),
      actions: [
        TextButton.icon(
          key: const ValueKey('cancel-snap-payment'),
          onPressed: _isCancelling ? null : _confirmCancel,
          icon: const Icon(Icons.close, size: 18),
          label: Text(_isCancelling ? 'Membatalkan...' : 'Batalkan'),
        ),
      ],
    );
  }

  Widget _buildVaContent() {
    if (_controller == null) {
      return const Center(child: Text('URL pembayaran tidak tersedia.'));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: WebViewWidget(controller: _controller!),
    );
  }

  Widget _buildQrisContent(BuildContext context) {
    final qrString = widget.saleResult.qrString;
    final qrCodeUrl = widget.saleResult.qrCodeUrl;
    if ((qrString == null || qrString.isEmpty) &&
        (qrCodeUrl == null || qrCodeUrl.isEmpty)) {
      return const Center(
        child: Text(
          'Kode QR tidak tersedia dari server. Batalkan lalu buat transaksi baru.',
          textAlign: TextAlign.center,
        ),
      );
    }
    final expired = _hasExpiry && _remaining.inSeconds <= 0;
    final countdownText = !_hasExpiry
        ? 'Kode QR berlaku hingga pembayaran selesai.'
        : expired
        ? 'Kode QR kedaluwarsa.'
        : 'Berlaku hingga ${_formatDuration(_remaining)}';
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            formatPrice(widget.saleResult.grandTotal),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.forestGreen),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: qrString != null && qrString.isNotEmpty
                ? QrImageView(
                    data: qrString,
                    size: 220,
                    backgroundColor: AppColors.surface,
                  )
                : Image.network(
                    qrCodeUrl!,
                    width: 220,
                    height: 220,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : const SizedBox.square(
                            dimension: 32,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                    errorBuilder: (_, _, _) => const Text(
                      'Gambar QR gagal dimuat. Periksa koneksi lalu coba lagi.',
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            countdownText,
            key: const ValueKey('qris-countdown'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: expired ? AppColors.error : AppColors.textMuted,
            ),
          ),
          if (expired) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: const ValueKey('qris-new-sale'),
              onPressed: _isCancelling ? null : _cancelAndClose,
              icon: const Icon(Icons.refresh),
              label: Text(_isCancelling ? 'Membatalkan...' : 'Buat baru'),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatDuration(Duration value) {
  final total = value.inSeconds.clamp(0, 99 * 3600 + 59 * 60 + 59);
  final minutes = (total ~/ 60).toString().padLeft(2, '0');
  final seconds = (total % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
