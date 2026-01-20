// ============================================
// lib/core/utils/formatters.dart
// ============================================
import 'package:intl/intl.dart';

class Formatters {
  static String currency(double amount, {String symbol = 'KES '}) {
    final formatter = NumberFormat.currency(symbol: symbol);
    return formatter.format(amount);
  }

  static String compactCurrency(double amount, {String symbol = 'KES '}) {
    final formatter = NumberFormat.compactCurrency(symbol: symbol);
    return formatter.format(amount);
  }

  static String date(DateTime date, {String format = 'MMM dd, yyyy'}) {
    final formatter = DateFormat(format);
    return formatter.format(date);
  }

  static String dateTime(DateTime dateTime, {String format = 'MMM dd, yyyy HH:mm'}) {
    final formatter = DateFormat(format);
    return formatter.format(dateTime);
  }

  static String phoneNumber(String phone) {
    // Format: +254 712 345 678
    if (phone.startsWith('+')) {
      if (phone.length == 13) {
        return '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7, 10)} ${phone.substring(10)}';
      }
    }
    return phone;
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String titleCase(String text) {
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }
}
