import 'package:intl/intl.dart';

String formatPrice(num value) => 'Rp ${value.toStringAsFixed(0)}';

String formatDateTime(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('d MMM yyyy, HH.mm', 'id_ID').format(value.toLocal());
}

String formatDate(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('d MMM yyyy', 'id_ID').format(value.toLocal());
}
