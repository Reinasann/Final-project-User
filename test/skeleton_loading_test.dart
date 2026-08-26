import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_admin/widgets/skeleton_loading.dart';

void main() {
  testWidgets('renders an accessible animated skeleton for every layout', (
    tester,
  ) async {
    for (final layout in AppSkeletonLayout.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppSkeletonLoading(layout: layout)),
        ),
      );
      expect(find.bySemanticsLabel('กำลังโหลดข้อมูล'), findsOneWidget);
      expect(find.byType(AppSkeletonLoading), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 120));
    }
  });
}
