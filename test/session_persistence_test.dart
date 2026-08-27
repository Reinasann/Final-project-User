import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_admin/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await ApiService.clearSession();
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('restores the signed-in user after the app process restarts', () async {
    final user = <String, dynamic>{
      'id': 'U001',
      'name': 'ผู้เก็บขยะ',
      'email': 'collector@example.com',
      'role': 'Collector',
      'organization_name': 'หน่วยงานทดสอบ',
    };
    FlutterSecureStorage.setMockInitialValues({
      'smart_recycle_access_token': 'persisted-access-token',
      'smart_recycle_user': jsonEncode(user),
    });

    final restoredUser = await ApiService.restoreSession();

    expect(restoredUser, user);
  });
}
