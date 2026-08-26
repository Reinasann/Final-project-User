import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/push_notification_service.dart';
import '../../services/session_service.dart';
import '../auth/login_page.dart';
import '../../widgets/skeleton_loading.dart';
import 'change_password_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  bool _loggingOut = false;
  String? _error;
  StreamSubscription<ApiResource>? _cacheSubscription;

  @override
  void initState() {
    super.initState();
    _cacheSubscription = ApiService.cacheUpdates
        .where((resource) => resource == ApiResource.profile)
        .listen((_) => _loadProfile(silent: true));
    _loadProfile();
  }

  Future<void> _loadProfile({
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    setState(() {
      _loading = currentUser.id.isEmpty && !silent;
      if (!silent) _error = null;
    });
    try {
      final user = await ApiService.me(forceRefresh: forceRefresh);
      currentUser.id = '${user['id']}';
      currentUser.name = '${user['name']}';
      currentUser.email = '${user['email']}';
      currentUser.phone = '${user['phone'] ?? ''}';
      currentUser.role = '${user['role']}';
      currentUser.organizationName = '${user['organization_name'] ?? ''}';
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _cacheSubscription?.cancel();
    super.dispose();
  }

  String _roleLabel(String role) {
    return switch (role) {
      'Collector' => 'เจ้าหน้าที่เก็บขยะ',
      'Organization admin' => 'ผู้ดูแลหน่วยงาน',
      'Super admin' => 'ผู้ดูแลระบบ',
      _ => role,
    };
  }

  Future<void> _editProfile() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
    if (changed == true) await _loadProfile();
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await PushNotificationService.deactivateForCurrentUser();
    } catch (_) {
      // ออกจากระบบต่อได้แม้ Firebase ไม่พร้อมใช้งาน
    }
    try {
      await ApiService.logout();
    } catch (_) {
      await ApiService.clearSession();
    }
    clearCurrentUser();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อมูลส่วนตัว'),
        actions: [
          IconButton(
            tooltip: 'โหลดข้อมูลใหม่',
            onPressed: () => _loadProfile(forceRefresh: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const AppSkeletonLoading(layout: AppSkeletonLayout.profile)
          : _error != null
              ? Center(
                  child: FilledButton.icon(
                    onPressed: () => _loadProfile(forceRefresh: true),
                    icon: const Icon(Icons.refresh),
                    label: Text('โหลดข้อมูลไม่สำเร็จ: $_error\nลองอีกครั้ง'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadProfile(forceRefresh: true),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.teal,
                              child: Text(
                                currentUser.name.isEmpty
                                    ? '?'
                                    : currentUser.name.characters.first,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                ),
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
                                  Text(_roleLabel(currentUser.role)),
                                  if (currentUser.organizationName.isNotEmpty)
                                    Text(
                                      currentUser.organizationName,
                                      style: TextStyle(
                                        color: Colors.teal.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'แก้ไขข้อมูล',
                              onPressed: _editProfile,
                              icon: const Icon(Icons.edit, color: Colors.teal),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoTile(
                        icon: Icons.email_outlined,
                        label: 'อีเมล',
                        value: currentUser.email,
                      ),
                      _InfoTile(
                        icon: Icons.phone_outlined,
                        label: 'เบอร์โทรศัพท์',
                        value: currentUser.phone.isEmpty
                            ? 'ยังไม่ได้ระบุ'
                            : currentUser.phone,
                      ),
                      _InfoTile(
                        icon: Icons.business_outlined,
                        label: 'หน่วยงาน',
                        value: currentUser.organizationName.isEmpty
                            ? 'ผู้ดูแลระบบ'
                            : currentUser.organizationName,
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          'บัญชีผู้ใช้',
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ListTile(
                        tileColor: Colors.white,
                        leading: const Icon(Icons.person_outline),
                        title: const Text('แก้ไขข้อมูลส่วนตัว'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _editProfile,
                      ),
                      ListTile(
                        tileColor: Colors.white,
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('เปลี่ยนรหัสผ่าน'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _loggingOut ? null : _logout,
                          icon: _loggingOut
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.logout),
                          label: Text(
                            _loggingOut ? 'กำลังออกจากระบบ…' : 'ออกจากระบบ',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.white,
      leading: Icon(icon, color: Colors.teal),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
