import 'dart:async';

import 'package:flutter/material.dart';
import 'forgot_password_page.dart';
import '../main_layout.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';
import '../../services/push_notification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailCtrl = TextEditingController(
    text: 'staff@recycle.com',
  );
  final TextEditingController _passCtrl =
      TextEditingController(text: '12345678');
  bool _obscurePassword = true;
  bool _loggingIn = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    String email = _emailCtrl.text.trim();
    String pass = _passCtrl.text.trim();

    setState(() => _loggingIn = true);
    try {
      final user = await ApiService.login(email, pass);
      if (!mounted) return;
      applyCurrentUser(user);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
      unawaited(PushNotificationService.activateForCurrentUser());
    } catch (error) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('เข้าสู่ระบบไม่สำเร็จ'),
          content: Text(
            error is ApiException
                ? error.message
                : 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้\n'
                    'กรุณาตรวจสอบว่า Django ทำงานอยู่ที่ ${ApiService.baseUrl}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                semanticLabel: 'โลโก้ Smart Recycle',
              ),
              const SizedBox(height: 20),
              const Text(
                'Smart Recycle',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                'สำหรับเจ้าหน้าที่จัดเก็บ',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  labelText: 'อีเมล',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'รหัสผ่าน',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    tooltip: _obscurePassword ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'ลืมรหัสผ่าน?',
                    style: TextStyle(color: Colors.teal),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loggingIn ? null : _handleLogin,
                  child: _loggingIn
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('เข้าสู่ระบบ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
