import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_admin/services/label_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds a printable Thai collection label PDF', () async {
    final bytes = await LabelPdfService.buildLabel(
      batchCode: 'LBL-M001-20260806123000',
      machineName: 'สถานีรีไซเคิล A',
      wasteType: 'พลาสติก (PET)',
      weightKg: 12.50,
      collectedAt: DateTime(2026, 8, 6, 12, 30),
      collectorName: 'เจ้าหน้าที่เก็บขยะ',
    );

    expect(bytes.length, greaterThan(5000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');

    final outputDirectory = Directory('output/pdf');
    outputDirectory.createSync(recursive: true);
    File('${outputDirectory.path}/sample_recycle_collection_label.pdf')
        .writeAsBytesSync(bytes);
  });
}
