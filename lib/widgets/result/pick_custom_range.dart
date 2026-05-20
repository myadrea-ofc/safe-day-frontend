import 'package:flutter/material.dart';

Future<DateTimeRange?> pickCustomRange({
  required BuildContext context,
  DateTimeRange? initialDateRange,
}) async {
  final picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: DateTime.now().add(const Duration(days: 365)),
    initialDateRange: initialDateRange,
  );
  if (picked == null) return null;

  final start = DateTime(
    picked.start.year,
    picked.start.month,
    picked.start.day,
  );
  final endExclusive = DateTime(
    picked.end.year,
    picked.end.month,
    picked.end.day,
  ).add(const Duration(days: 1));

  return DateTimeRange(start: start, end: endExclusive);
}
