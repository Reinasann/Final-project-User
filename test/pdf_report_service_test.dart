import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_admin/models/models.dart';
import 'package:recycle_admin/services/pdf_report_service.dart';
import 'package:recycle_admin/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds a Thai user collection report PDF', () async {
    currentUser.id = 'U001';
    currentUser.name = 'เจ้าหน้าที่ทดสอบ';
    currentUser.organizationName = 'หน่วยงานทดสอบระบบรีไซเคิล';

    final dates = List.generate(
      7,
      (index) => DateTime(2026, 7, 17 + index),
    );
    final history = [
      CollectionHistoryItem(
        id: 'H001',
        date: '21/07/2026',
        time: '10:30',
        machineId: 'M001',
        machineName: 'สถานีรีไซเคิล A',
        type: 'พลาสติก',
        weight: '3.40 กก.',
      ),
      CollectionHistoryItem(
        id: 'H002',
        date: '22/07/2026',
        time: '14:15',
        machineId: 'M001',
        machineName: 'สถานีรีไซเคิล A',
        type: 'แก้ว',
        weight: '5.80 กก.',
      ),
      CollectionHistoryItem(
        id: 'H003',
        date: '23/07/2026',
        time: '09:10',
        machineId: 'M002',
        machineName: 'สถานีรีไซเคิล B',
        type: 'กระป๋อง',
        weight: '1.70 กก.',
      ),
    ];
    final issues = [
      IssueReportItem(
        id: 'I001',
        machineId: 'M001',
        machineName: 'สถานีรีไซเคิล A',
        title: 'เซ็นเซอร์ผิดปกติ',
        description: 'ค่าระดับขยะไม่เปลี่ยนแปลง',
        date: '23/07/2026',
        status: 'Waiting',
      ),
    ];

    final bytes = await PdfReportService.buildUserCollectionReport(
      periodLabel: '17/07/2026 - 23/07/2026',
      machineLabel: 'ทุกเครื่อง',
      wasteTypeLabel: 'ทุกประเภท',
      totals: const {
        'total': 10.90,
        'plastic': 3.40,
        'glass': 5.80,
        'can': 1.70,
      },
      history: history,
      issues: issues,
      chartDates: dates,
      chartSeries: const [
        PdfChartSeries(
          name: 'สถานีรีไซเคิล A',
          colorHex: '#2DD4BF',
          values: [0, 0, 0, 0, 3.4, 5.8, 0],
        ),
        PdfChartSeries(
          name: 'สถานีรีไซเคิล B',
          colorHex: '#60A5FA',
          values: [0, 0, 0, 0, 0, 0, 1.7],
        ),
      ],
      sections: const PdfReportSections(chart: false),
    );

    expect(bytes.length, greaterThan(10000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');

    final outputDirectory = Directory('output/pdf');
    outputDirectory.createSync(recursive: true);
    File('${outputDirectory.path}/sample_user_collection_report.pdf')
        .writeAsBytesSync(bytes);
  });
}
