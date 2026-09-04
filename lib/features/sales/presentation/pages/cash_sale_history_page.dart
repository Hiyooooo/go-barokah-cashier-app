import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/async_state_widgets.dart';
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
        data: (page) => _HistoryContent(page: page),
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
  const _HistoryContent({required this.page});

  final CashSaleHistoryResponse page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (page.items.isEmpty) {
      return const AppEmpty(message: 'No sales found.');
    }

    final meta = page.meta;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...page.items.map(
          (sale) => Card(
            child: ListTile(
              onTap: () => context.push('/receipt/${sale.saleNumber}'),
              title: Text(sale.saleNumber),
              subtitle: Text(
                '${sale.paymentMethod} | ${sale.createdAt?.toLocal() ?? '-'}',
              ),
              trailing: Text(_price(sale.grandTotal)),
            ),
          ),
        ),
        if (meta != null && meta.totalPages > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: meta.page > 1
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
                onPressed: meta.page < meta.totalPages
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

String _price(num value) => 'Rp ${value.toStringAsFixed(0)}';
