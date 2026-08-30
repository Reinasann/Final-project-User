import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_admin/models/models.dart';

void main() {
  test('machine reads valid coordinates from the API', () {
    final machine = Machine.fromApi({
      'id': 'M001',
      'name': 'สถานีรีไซเคิล A',
      'location': 'อาคาร A',
      'latitude': '13.756300',
      'longitude': '100.501800',
      'status': 'Online',
      'caretakers': [
        {'id': 'U001', 'name': 'ผู้ดูแลเครื่อง A'},
        {'id': 'U002', 'name': 'ผู้ดูแลเครื่อง B'},
      ],
      'can_operate': true,
      'bins': <Map<String, dynamic>>[],
    });

    expect(machine.latitude, 13.7563);
    expect(machine.longitude, 100.5018);
    expect(machine.hasCoordinates, isTrue);
    expect(machine.caretakerId, 'U001');
    expect(machine.caretakerIds, ['U001', 'U002']);
    expect(machine.caretakerName, 'ผู้ดูแลเครื่อง A, ผู้ดูแลเครื่อง B');
    expect(machine.canOperate, isTrue);
  });

  test('machine without complete coordinates is not placed on the map', () {
    final machine = Machine(
      id: 'M002',
      name: 'ยังไม่มีพิกัด',
      location: 'อาคาร B',
      latitude: 13.7563,
    );

    expect(machine.hasCoordinates, isFalse);
  });
}
