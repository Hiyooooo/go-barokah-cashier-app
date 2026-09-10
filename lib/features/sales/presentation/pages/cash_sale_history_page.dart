import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/async_state_widgets.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/cash_sale_history_models.dart';
import '../providers/cash_sale_history_provider.dart';

class CashSaleHistoryPage extends ConsumerWidget {
  const CashSaleHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(cashSaleHistoryProvider);
    final notifier = ref.read(cashSaleHistoryProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales history'),
        actions: [
          IconButton(
            tooltip: 'Refresh sales history',
            onPressed: history.isLoading
                ? null
                : () => ref.invalidate(cashSaleHistoryProvider),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Filter by date',
            onPressed: () => _pickDates(context, notifier),
            icon: const Icon(Icons.date_range),
          ),
        ],
      ),
      body: history.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: userFacingError(
            error,
            fallback: 'Unable to load sales history.',
          ),
          onRetry: () => ref.invalidate(cashSaleHistoryProvider),
        ),
        data: (page) => _HistoryContent(
          page: page,
          startDate: notifier.startDate,
          endDate: notifier.endDate,
          onResetDates: () => notifier.applyDates(),
        ),
      ),
    );
  }

  Future<void> _pickDates(
    BuildContext context,
    CashSaleHistoryNotifier notifier,
  ) async {
    final start = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: notifier.startDate ?? DateTime.now(),
    );
    if (!context.mounted || start == null) return;

    final end = await showDatePicker(
      context: context,
      firstDate: start,
      lastDate: DateTime.now(),
      initialDate: notifier.endDate ?? start,
    );
    if (end == null) return;
    await notifier.applyDates(startDate: start, endDate: end);
  }
}

class _HistoryContent extends ConsumerWidget {
  const _HistoryContent({
    required this.page,
    this.startDate,
    this.endDate,
    required this.onResetDates,
  });

  final CashSaleHistoryResponse page;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onResetDates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(cashSaleHistoryProvider).isLoading;
    if (page.items.isEmpty) {
      return const AppEmpty(message: 'No sales found.');
    }

    final meta = page.meta;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (startDate != null || endDate != null)
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filter: ${_formatDate(startDate)} - ${_formatDate(endDate)}',
                ),
              ),
              TextButton(onPressed: onResetDates, child: const Text('Reset')),
            ],
          ),
        ...page.items.map(
          (sale) => Card(
            child: ListTile(
              onTap: () => context.push('/receipt/${sale.saleNumber}'),
              title: Text(sale.saleNumber),
              subtitle: Text(
                '${sale.paymentMethod.toUpperCase()} | ${_formatDate(sale.createdAt)}',
              ),
              trailing: Text(formatPrice(sale.grandTotal)),
            ),
          ),
        ),
        if (meta != null && meta.totalPages > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: meta.page > 1 && !loading
                    ? () => ref
                          .read(cashSaleHistoryProvider.notifier)
                          .goToPage(meta.page - 1)
                    : null,
                child: const Text('Previous'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('Page ${meta.page} of ${meta.totalPages}'),
              ),
              OutlinedButton(
                onPressed: meta.page < meta.totalPages && !loading
                    ? () => ref
                          .read(cashSaleHistoryProvider.notifier)
                          .goToPage(meta.page + 1)
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

String _formatDate(DateTime? value) => value == null
    ? '-'
    : DateFormat('dd MMM yyyy, HH.mm', 'id_ID').format(value.toLocal());
