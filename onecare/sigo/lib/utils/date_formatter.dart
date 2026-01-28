import 'package:intl/intl.dart';

/// Formats a DateTime with localized month abbreviation
/// - Capitalizes first letter
/// - Removes trailing periods
String formatDate(
  DateTime date,
  String locale, {
  bool includeTime = true,
  String? formatPattern,
}) {
  final pattern = formatPattern ?? (includeTime ? 'dd MMM yyyy - HH:mm' : 'dd MMM yyyy');
  final formatter = DateFormat(pattern, locale);
  final formatted = formatter.format(date);

  // Remove periods and ensure first letter of month is capitalized
  return formatted
      .replaceAll('.', '') // Remove periods
      .split(' ') // Split into parts
      .map((part) {
        // Capitalize first letter of each part (especially month)
        if (part.isEmpty) return part;
        return part[0].toUpperCase() + part.substring(1).toLowerCase();
      })
      .join(' '); // Join back together
}
