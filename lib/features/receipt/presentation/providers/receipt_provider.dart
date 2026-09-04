import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/receipt_models.dart';
import '../../data/repositories/receipt_repository.dart';

final receiptRepositoryProvider = Provider<ReceiptRepository>(
  (ref) => ReceiptRepository(apiClient: ref.watch(apiClientProvider)),
);

final receiptProvider = FutureProvider.autoDispose.family<Receipt, String>(
  (ref, saleNumber) =>
      ref.watch(receiptRepositoryProvider).getReceipt(saleNumber),
);
