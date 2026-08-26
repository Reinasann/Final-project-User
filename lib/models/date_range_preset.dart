import 'dart:math' as math;

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
  AppDateRangePreset('3m', '3 เดือน'),
  AppDateRangePreset('6m', '6 เดือน'),
  AppDateRangePreset('1y', '1 ปี'),
  AppDateRangePreset('custom', 'กำหนดเอง', isCustom: true),
];

DateTime _subtractMonthsClamped(DateTime date, int months) {
  final monthIndex = date.year * 12 + date.month - 1 - months;
  final year = monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, math.min(date.day, lastDay));
}

DateTimeRange appPresetDateRange(String key, DateTime rangeEnd) {
  final end = DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day);
  late final DateTime start;
  switch (key) {
    case '30d':
      start = end.subtract(const Duration(days: 29));
    case '3m':
      start = _subtractMonthsClamped(end, 3).add(const Duration(days: 1));
    case '6m':
      start = _subtractMonthsClamped(end, 6).add(const Duration(days: 1));
    case '1y':
      start = _subtractMonthsClamped(end, 12).add(const Duration(days: 1));
    default:
      start = end.subtract(const Duration(days: 6));
  }
  return DateTimeRange(start: start, end: end);
}
