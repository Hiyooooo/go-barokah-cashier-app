import 'package:intl/intl.dart';

final _idr = NumberFormat('#,###', 'id_ID');

String formatPrice(num value) => 'Rp ${_idr.format(value)}';

String formatDateTime(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('d MMM yyyy, HH.mm', 'id_ID').format(value.toLocal());
}

String formatDate(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('d MMM yyyy', 'id_ID').format(value.toLocal());
}
