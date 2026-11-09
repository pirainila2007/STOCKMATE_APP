import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat _decimal = NumberFormat('#,##0.00');
  static final NumberFormat _whole = NumberFormat('#,##0');

  /// LKR 1,250.00
  static String money(num amount) => 'LKR ${_decimal.format(amount)}';

  /// LKR 1,250
  static String moneyShort(num amount) => 'LKR ${_whole.format(amount)}';

  static String number(num value) => _whole.format(value);

  static String percent(double ratio) => '${(ratio * 100).round()}%';

  static String dateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
  }

  static String time(DateTime date) {
    return DateFormat('hh:mm a').format(date.toLocal());
  }

  static String weekday(DateTime date) {
    return DateFormat('EEE').format(date.toLocal());
  }

  /// Today / Yesterday / 27 Oct 2026
  static String dayLabel(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final diff = today.difference(day).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('dd MMM yyyy').format(local);
  }
}