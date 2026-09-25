import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_admin/models/models.dart';

void main() {
  test('formats app dates as dd/mm/yyyy', () {
    expect(formatAppDate(DateTime(2026, 8, 5)), '05/08/2026');
  });

  test('parses display and API date formats', () {
    expect(parseAppDate('05/08/2026'), DateTime(2026, 8, 5));
    expect(parseAppDate('2026-08-05T10:30:00+07:00'), DateTime(2026, 8, 5));
  });

  test('แสดงสถานะแจ้งซ่อมเป็นภาษาไทย', () {
    IssueReportItem issue(String status) => IssueReportItem(
          id: '1',
          machineId: 'M001',
          title: 'ทดสอบ',
          description: 'ทดสอบ',
          date: '24/09/2026',
          status: status,
        );

    expect(issue('Waiting').statusLabel, 'รอดำเนินการ');
    expect(issue('In Progress').statusLabel, 'กำลังดำเนินการ');
    expect(issue('Completed').statusLabel, 'เสร็จสิ้น');
  });
}
