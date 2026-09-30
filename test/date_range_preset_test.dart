import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_admin/models/date_range_preset.dart';

void main() {
  test('exposes the requested Thai date-range options in order', () {
    expect(
      appDateRangePresets.map((preset) => preset.label).toList(),
      ['7 วัน', '30 วัน', 'กำหนดเอง'],
    );
  });

  test('calculates 7-day and 30-day presets as inclusive ranges', () {
    final end = DateTime(2026, 8, 15);

    expect(appPresetDateRange('7d', end).start, DateTime(2026, 8, 9));
    expect(appPresetDateRange('30d', end).start, DateTime(2026, 7, 17));
  });
}
