import 'package:intl/intl.dart';

class FormatUtils {
  static final NumberFormat _vnd = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final DateFormat _dateTimeVi = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _dateVi = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeShortVi = DateFormat('dd/MM HH:mm');
  static final DateFormat _timeVi = DateFormat('HH:mm');

  static String vnd(num value) => _vnd.format(value);

  /// Compact VND formatting used in some UI surfaces (e.g. 12k₫, 1.2M₫).
  static String vndCompact(num value) {
    final v = value.toDouble();
    if (v.abs() >= 1000000000) {
      return '${(v / 1000000000).toStringAsFixed(1)}B₫';
    }
    if (v.abs() >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1)}M₫';
    }
    if (v.abs() >= 1000) {
      return '${(v / 1000).toStringAsFixed(0)}k₫';
    }
    return '${v.toStringAsFixed(0)}₫';
  }

  /// Compact format for charts/axis where currency symbol is too noisy.
  static String vndCompactNoSymbol(num value) =>
      vndCompact(value).replaceAll('₫', '');

  static String dateTimeVi(DateTime d) => _dateTimeVi.format(d);

  static String dateVi(DateTime d) => _dateVi.format(d);

  static String dateTimeShortVi(DateTime d) => _dateTimeShortVi.format(d);

  static String timeVi(DateTime d) => _timeVi.format(d);
}

