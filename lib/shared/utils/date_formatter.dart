import 'package:intl/intl.dart';

class DateFormatter {
  static String formatJournalDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(dt.year, dt.month, dt.day);

    if (entryDate == today) {
      return 'Today, ${DateFormat('h:mm a').format(dt)}';
    } else if (entryDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${DateFormat('h:mm a').format(dt)}';
    } else if (now.year == dt.year) {
      return DateFormat('EEEE, d MMMM').format(dt);
    } else {
      return DateFormat('d MMMM yyyy').format(dt);
    }
  }

  static String formatMonthYear(DateTime dt) {
    return DateFormat('MMMM yyyy').format(dt);
  }

  static String formatShortDate(DateTime dt) {
    return DateFormat('MMM d, yyyy').format(dt);
  }
}
