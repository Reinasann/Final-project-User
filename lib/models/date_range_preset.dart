import 'package:flutter/material.dart';

class AppDateRangePreset {
  final String key;
  final String label;
  final bool isCustom;

  const AppDateRangePreset(this.key, this.label, {this.isCustom = false});
}

const appDateRangePresets = <AppDateRangePreset>[
  AppDateRangePreset('7d', '7 วัน'),
  AppDateRangePreset('30d', '30 วัน'),
  AppDateRangePreset('custom', 'กำหนดเอง', isCustom: true),
];

DateTimeRange appPresetDateRange(String key, DateTime rangeEnd) {
  final end = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
  late final DateTime start;
  switch (key) {
    case '30d':
      start = end.subtract(const Duration(days: 29));
    default:
      start = end.subtract(const Duration(days: 6));
  }
  return DateTimeRange(start: start, end: end);
}
