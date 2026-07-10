import 'package:flutter/material.dart';
import '../../data/dummy_data.dart';
import '../auth/login_page.dart';
import 'edit_profile_page.dart';
import 'change_password_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ข้อมูลส่วนตัว')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.teal,
                    child: Text(
                      currentUser.name[0],
                      style: const TextStyle(fontSize: 30, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currentUser.role,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          currentUser.id,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.teal),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => const EditProfilePage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

           // _buildSectionHeader(context, 'ข้อมูลการทำงาน'),
            //_buildInfoCard(Icons.badge, 'รหัสพนักงาน', currentUser.id),
            //_buildInfoCard(
             // Icons.calendar_today,
             // 'วันที่เริ่มงาน',
             // currentUser.startDate,
            //),

            _buildSectionHeader(context, 'บัญชีผู้ใช้'),
            _buildSettingItem(
              context,
              Icons.person_outline,
              'แก้ไขข้อมูลส่วนตัว',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const EditProfilePage()),
              ),
            ),
            _buildSettingItem(
              context,
              Icons.lock_outline,
              'เปลี่ยนรหัสผ่าน',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const ChangePasswordPage()),
              ),
            ),

            //_buildSectionHeader(context, 'ความปลอดภัย'),
           // _buildSettingItem(
           //   context,
           //    Icons.security,
            //  'การยืนยันตัวตน 2 ชั้น',
            //  () => _showDummyDialog(context, '2FA', 'ระบบกำลังพัฒนา'),
           // ),

            _buildSectionHeader(context, 'การตั้งค่า'),
            _buildSwitchItem(
              Icons.notifications_outlined,
              'การแจ้งเตือน (Push)',
              true,
            ),
            _buildSwitchItem(Icons.email_outlined, 'แจ้งเตือนผ่านอีเมล', false),
            //_buildSettingItem(
            //  context,
            //  Icons.language,
            //  'ภาษา',
            //  () => _showDummyDialog(
            //    context,
            //    'ตั้งค่าภาษา',
            //    'คุณสามารถเปลี่ยนภาษาได้ในเวอร์ชันถัดไป',
            //  ),
            //),

            _buildSectionHeader(context, 'อื่นๆ'),
            _buildSettingItem(
              context,
              Icons.help_outline,
              'ศูนย์ช่วยเหลือ',
              () => _showDummyDialog(
                context,
                'ศูนย์ช่วยเหลือ',
                'ติดต่อ Admin: 02-xxx-xxxx\nEmail: help@recycle.com',
              ),
            ),
            _buildSettingItem(
              context,
              Icons.privacy_tip_outlined,
              'นโยบายความเป็นส่วนตัว',
              () => _showDummyDialog(
                context,
                'Privacy Policy',
                'รายละเอียดนโยบาย...',
              ),
            ),
            _buildSettingItem(
              context,
              Icons.description_outlined,
              'เงื่อนไขการใช้งาน',
              () => _showDummyDialog(
                context,
                'Terms of Service',
                'รายละเอียดเงื่อนไข...',
              ),
            ),
            _buildSettingItem(
              context,
              Icons.info_outline,
              'เกี่ยวกับแอปพลิเคชัน',
              () => showAboutDialog(
                context: context,
                applicationName: 'Smart Recycle',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 Recycle Co., Ltd.',
              ),
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (c) => const LoginPage()),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('ออกจากระบบ'),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showDummyDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.teal[800],
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 1),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchItem(IconData icon, String title, bool value) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(title),
        trailing: Switch(
          value: value,
          activeColor: Colors.teal,
          onChanged: (val) {},
        ),
      ),
    );
  }
}

