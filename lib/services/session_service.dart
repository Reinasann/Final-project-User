import '../models/models.dart';

/// ข้อมูลผู้ใช้ที่เข้าสู่ระบบ เป็นแคชสำหรับแสดงผลระหว่างที่แอปทำงาน
/// ข้อมูลถาวรทั้งหมดอ่านและบันทึกผ่าน Django API
final currentUser = User(id: '', name: '', role: '');

void applyCurrentUser(Map<String, dynamic> user) {
  currentUser.id = '${user['id'] ?? ''}';
  currentUser.name = '${user['name'] ?? ''}';
  currentUser.role = '${user['role'] ?? ''}';
  currentUser.email = '${user['email'] ?? ''}';
  currentUser.phone = '${user['phone'] ?? ''}';
  currentUser.organizationName = '${user['organization_name'] ?? ''}';
}

void clearCurrentUser() {
  currentUser.id = '';
  currentUser.name = '';
  currentUser.role = '';
  currentUser.email = '';
  currentUser.phone = '';
  currentUser.organizationName = '';
}
