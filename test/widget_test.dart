import 'package:flutter_test/flutter_test.dart';

import 'package:recycle_admin/main.dart';

void main() {
  testWidgets('shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const RecycleApp());

    expect(find.text('Smart Recycle'), findsOneWidget);
    expect(find.byType(RecycleApp), findsOneWidget);
  });
}
