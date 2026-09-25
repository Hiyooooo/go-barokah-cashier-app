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
              onPickDates: () => _pickDates(context, notifier),
              onApplyDates: (start, end) =>
                  notifier.applyDates(startDate: start, endDate: end),
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
                onPickDates: () => _pickDates(context, notifier),
                onApplyDates: (start, end) =>
                    notifier.applyDates(startDate: start, endDate: end),
              ),
            ),
    );
  }

  Future<void> _pickDates(
    BuildContext context,
    CashSaleHistoryNotifier notifier,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var start = notifier.startDate ?? today;
    var end = notifier.endDate ?? today;

    final result = await showDialog<DateTimeRange>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Rentang Tanggal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pilih tanggal awal dan akhir transaksi.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: const BorderSide(color: AppColors.border),
                ),
                leading: const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.forestGreen,
                ),
                title: const Text('Dari tanggal'),
                subtitle: Text(
                  formatDate(start),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: today,
                    initialDate: start.isAfter(today) ? today : start,
                  );
                  if (picked != null) {
                    setDialogState(() {
                      start = picked;
                      if (end.isBefore(start)) end = start;
                    });
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: const BorderSide(color: AppColors.border),
                ),
                leading: const Icon(
                  Icons.event_available_outlined,
                  color: AppColors.forestGreen,
                ),
                title: const Text('Sampai tanggal'),
                subtitle: Text(
                  formatDate(end),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: start,
                    lastDate: today,
                    initialDate: end.isBefore(start)
                        ? start
                        : (end.isAfter(today) ? today : end),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      end = picked;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                DateTimeRange(start: start, end: end),
              ),
              child: const Text('Terapkan'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted || result == null) return;
    await notifier.applyDates(startDate: result.start, endDate: result.end);
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
    required this.onPickDates,
    required this.onApplyDates,
    this.error,
  });

  final CashSaleHistoryResponse page;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isRefreshing;
  final Object? error;
  final VoidCallback onResetDates;
  final VoidCallback onRetry;
  final VoidCallback onPickDates;
  final void Function(DateTime? start, DateTime? end) onApplyDates;

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
                onPickDates: onPickDates,
                onApplyDates: onApplyDates,
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
    required this.onPickDates,
    required this.onApplyDates,
  });

  final int? total;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isRefreshing;
  final VoidCallback onResetDates;
  final VoidCallback onPickDates;
  final void Function(DateTime? start, DateTime? end) onApplyDates;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 6));
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    final isAll = startDate == null && endDate == null;
    final isToday =
        startDate != null &&
        endDate != null &&
        _isSameDay(startDate, today) &&
        _isSameDay(endDate, today);
    final isLast7Days =
        startDate != null &&
        endDate != null &&
        _isSameDay(startDate, sevenDaysAgo) &&
        _isSameDay(endDate, today);
    final isThisMonth =
        startDate != null &&
        endDate != null &&
        _isSameDay(startDate, firstDayOfMonth) &&
        _isSameDay(endDate, today);
    final isCustom = !isAll && !isToday && !isLast7Days && !isThisMonth;

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
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                key: const ValueKey('filter-all-history'),
                label: const Text('Semua'),
                selected: isAll,
                onSelected: isRefreshing ? null : (_) => onResetDates(),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilterChip(
                key: const ValueKey('filter-today-history'),
                label: const Text('Hari ini'),
                selected: isToday,
                onSelected: isRefreshing
                    ? null
                    : (_) => onApplyDates(today, today),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilterChip(
                key: const ValueKey('filter-7days-history'),
                label: const Text('7 hari terakhir'),
                selected: isLast7Days,
                onSelected: isRefreshing
                    ? null
                    : (_) => onApplyDates(sevenDaysAgo, today),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilterChip(
                key: const ValueKey('filter-month-history'),
                label: const Text('Bulan ini'),
                selected: isThisMonth,
                onSelected: isRefreshing
                    ? null
                    : (_) => onApplyDates(firstDayOfMonth, today),
              ),
              const SizedBox(width: AppSpacing.sm),
              ActionChip(
                key: const ValueKey('filter-custom-dates'),
                avatar: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  isCustom && startDate != null && endDate != null
                      ? '${formatDate(startDate)} - ${formatDate(endDate)}'
                      : 'Pilih rentang...',
                ),
                onPressed: isRefreshing ? null : onPickDates,
              ),
            ],
          ),
        ),
        if (!isAll) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.date_range_outlined, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Rentang aktif: ${formatDate(startDate)} s/d ${formatDate(endDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warmBrown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                ),
                onPressed: isRefreshing ? null : onResetDates,
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.sale});

  final CashSaleHistoryItem sale;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: InkWell(
      onTap: () => context.push('/receipt/${sale.saleNumber}'),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(AppRadius.badge),
                        ),
                        child: Text(
                          sale.paymentMethod.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.warmBrown,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          formatDateTime(sale.createdAt),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    sale.saleNumber,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              formatPrice(sale.grandTotal),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
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
