import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_state_widgets.dart';
import '../../data/models/cash_sale_history_models.dart';
import '../providers/cash_sale_history_provider.dart';

class CashSaleHistoryPage extends ConsumerWidget {
  const CashSaleHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(cashSaleHistoryProvider);
    final notifier = ref.read(cashSaleHistoryProvider.notifier);
    final current = history.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat transaksi'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang riwayat',
            onPressed: history.isLoading
                ? null
                : () => ref.invalidate(cashSaleHistoryProvider),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Filter tanggal',
            onPressed: history.isLoading
                ? null
                : () => _pickDates(context, notifier),
            icon: const Icon(Icons.date_range_outlined),
          ),
        ],
      ),
      body: current != null
          ? _HistoryContent(
              page: current,
              startDate: notifier.startDate,
              endDate: notifier.endDate,
              isRefreshing: history.isLoading,
              error: history.hasError ? history.error : null,
              onRetry: () => ref.invalidate(cashSaleHistoryProvider),
              onResetDates: () => notifier.applyDates(),
            )
          : history.when(
              loading: () => const AppLoading(),
              error: (error, _) => AppError(
                message: userFacingError(
                  error,
                  fallback: 'Riwayat transaksi belum dapat dimuat.',
                ),
                onRetry: () => ref.invalidate(cashSaleHistoryProvider),
              ),
              data: (page) => _HistoryContent(
                page: page,
                startDate: notifier.startDate,
                endDate: notifier.endDate,
                isRefreshing: false,
                onRetry: () => ref.invalidate(cashSaleHistoryProvider),
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
    if (!context.mounted || end == null) return;
    await notifier.applyDates(startDate: start, endDate: end);
  }
}

class _HistoryContent extends ConsumerWidget {
  const _HistoryContent({
    required this.page,
    required this.startDate,
    required this.endDate,
    required this.isRefreshing,
    required this.onResetDates,
    required this.onRetry,
    this.error,
  });

  final CashSaleHistoryResponse page;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isRefreshing;
  final Object? error;
  final VoidCallback onResetDates;
  final VoidCallback onRetry;

  bool get hasDateFilter => startDate != null || endDate != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = page.meta;
    final body = page.items.isEmpty
        ? _HistoryEmpty(hasDateFilter: hasDateFilter, onReset: onResetDates)
        : LayoutBuilder(
            builder: (context, constraints) {
              final rows = [
                for (final sale in page.items) _HistoryRow(sale: sale),
              ];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: rows,
                  ),
                ),
              );
            },
          );

    return RefreshIndicator(
      onRefresh: () => ref.refresh(cashSaleHistoryProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: _HistoryHeader(
                total: meta?.total,
                startDate: startDate,
                endDate: endDate,
                isRefreshing: isRefreshing,
                onResetDates: onResetDates,
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _HistoryError(error: error!, onRetry: onRetry),
          ],
          const SizedBox(height: AppSpacing.xxl),
          body,
          if (meta != null && meta.totalPages > 1) ...[
            const SizedBox(height: AppSpacing.xxl),
            _Pagination(meta: meta, isLoading: isRefreshing),
          ],
        ],
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({
    required this.total,
    required this.startDate,
    required this.endDate,
    required this.isRefreshing,
    required this.onResetDates,
  });

  final int? total;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isRefreshing;
  final VoidCallback onResetDates;

  @override
  Widget build(BuildContext context) {
    final hasFilter = startDate != null || endDate != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Transaksi cashier',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          total == null
              ? 'Riwayat transaksi Anda'
              : '$total transaksi ditemukan',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (hasFilter)
          Row(
            children: [
              const Icon(Icons.date_range_outlined, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${formatDate(startDate)} sampai ${formatDate(endDate)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: isRefreshing ? null : onResetDates,
                child: const Text('Reset tanggal'),
              ),
            ],
          ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.sale});

  final CashSaleHistoryItem sale;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    child: InkWell(
      onTap: () => context.push('/receipt/${sale.saleNumber}'),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.saleNumber,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${formatDateTime(sale.createdAt)} · ${sale.paymentMethod.toUpperCase()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Buka struk untuk melihat detail atau mencetak ulang.',
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPrice(sale.grandTotal),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.forestGreen,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Cetak ulang struk',
                      onPressed: () =>
                          context.push('/receipt/${sale.saleNumber}'),
                      icon: const Icon(Icons.print_outlined),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({required this.hasDateFilter, required this.onReset});

  final bool hasDateFilter;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Belum ada transaksi',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hasDateFilter
                ? 'Tidak ada transaksi pada periode ini.'
                : 'Transaksi cashier akan muncul di sini.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          if (hasDateFilter) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onReset,
              child: const Text('Reset tanggal'),
            ),
          ],
        ],
      ),
    ),
  );
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.errorContainer,
      borderRadius: BorderRadius.circular(AppRadius.badge),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            userFacingError(error, fallback: 'Pembaruan riwayat gagal.'),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
      ],
    ),
  );
}

class _Pagination extends ConsumerWidget {
  const _Pagination({required this.meta, required this.isLoading});

  final PaginationMeta meta;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: AppSpacing.md,
    runSpacing: AppSpacing.sm,
    children: [
      OutlinedButton(
        onPressed: meta.page > 1 && !isLoading
            ? () => ref
                  .read(cashSaleHistoryProvider.notifier)
                  .goToPage(meta.page - 1)
            : null,
        child: const Text('Sebelumnya'),
      ),
      Text('Halaman ${meta.page} dari ${meta.totalPages}'),
      OutlinedButton(
        onPressed: meta.page < meta.totalPages && !isLoading
            ? () => ref
                  .read(cashSaleHistoryProvider.notifier)
                  .goToPage(meta.page + 1)
            : null,
        child: const Text('Berikutnya'),
      ),
    ],
  );
}
