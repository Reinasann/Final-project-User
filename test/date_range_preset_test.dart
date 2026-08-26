import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_admin/models/date_range_preset.dart';

void main() {
  test('exposes the requested Thai date-range options in order', () {
    expect(
      appDateRangePresets.map((preset) => preset.label).toList(),
      ['7 วัน', '30 วัน', '3 เดือน', '6 เดือน', '1 ปี', 'กำหนดเอง'],
    );
  });

  test('calculates day, month, and year presets as inclusive ranges', () {
    final end = DateTime(2026, 8, 15);

    expect(appPresetDateRange('7d', end).start, DateTime(2026, 8, 9));
    expect(appPresetDateRange('30d', end).start, DateTime(2026, 7, 17));
    expect(appPresetDateRange('3m', end).start, DateTime(2026, 5, 16));
    expect(appPresetDateRange('6m', end).start, DateTime(2026, 2, 16));
    expect(appPresetDateRange('1y', end).start, DateTime(2025, 8, 16));
  });

  test('clamps calendar months safely around leap days', () {
    final range = appPresetDateRange('1y', DateTime(2024, 2, 29));
    expect(range.start, DateTime(2023, 3, 1));
    expect(range.end, DateTime(2024, 2, 29));
  });
}
