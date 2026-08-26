import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_admin/pages/label/label_print_page.dart';
import 'package:recycle_admin/services/session_service.dart';

void main() {
  testWidgets('offers printer and PDF output after collection', (tester) async {
    currentUser.name = 'ผู้ทดสอบระบบ';
    await tester.pumpWidget(
      MaterialApp(
        home: LabelPrintPage(
          machineName: 'สถานีรีไซเคิล A',
          preSelectedType: 'พลาสติก',
          weightKg: 4.25,
          collectedAt: DateTime(2026, 8, 6, 10, 30),
          batchCode: 'LBL-TEST-001',
          collectionSaved: true,
        ),
      ),
    );

    expect(
        find.textContaining('บันทึกการเก็บขยะลงฐานข้อมูลแล้ว'), findsOneWidget);
    expect(find.text('4.25 กก.'), findsOneWidget);

    final printButton = find.byIcon(Icons.print);
    await tester.ensureVisible(printButton);
    await tester.pumpAndSettle();
    await tester.tap(printButton);
    await tester.pumpAndSettle();

    expect(find.text('เลือกรูปแบบการพิมพ์'), findsOneWidget);
    expect(find.text('พิมพ์ด้วยเครื่องพิมพ์'), findsOneWidget);
    expect(find.text('พิมพ์เป็น PDF'), findsOneWidget);
  });
}
