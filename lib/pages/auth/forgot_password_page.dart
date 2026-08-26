import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  bool _codeRequested = false;
  bool _submitting = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_codeRequested && !(_emailFormKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await ApiService.requestPasswordReset(
        _emailController.text.trim(),
      );
      if (!mounted) return;
      final debugCode = result['debug_code']?.toString();
      setState(() {
        _codeRequested = true;
        if (debugCode != null && debugCode.isNotEmpty) {
          _codeController.text = debugCode;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            debugCode == null
                ? 'ส่งรหัสยืนยันไปยังอีเมลแล้ว'
                : 'โหมดพัฒนา: ระบบกรอกรหัสยืนยันให้แล้ว',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งรหัสยืนยันไม่สำเร็จ: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmReset() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ApiService.confirmPasswordReset(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('ตั้งรหัสผ่านสำเร็จ'),
          content: const Text('เข้าสู่ระบบด้วยรหัสผ่านใหม่ได้ทันที'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ตั้งรหัสผ่านไม่สำเร็จ: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลืมรหัสผ่าน')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _codeRequested ? _buildResetForm() : _buildEmailForm(),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'กรอกอีเมลที่ใช้ในระบบเพื่อรับรหัสยืนยัน 6 หลัก',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'อีเมล',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'กรุณากรอกอีเมล';
              if (!email.contains('@')) return 'รูปแบบอีเมลไม่ถูกต้อง';
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _submitting ? null : _requestCode,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('ส่งรหัสยืนยัน'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'กรอกรหัสยืนยันจากอีเมลและกำหนดรหัสผ่านใหม่',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _emailController.text.trim(),
            style: const TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'รหัสยืนยัน 6 หลัก',
              prefixIcon: Icon(Icons.pin_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) => (value?.trim().length ?? 0) == 6
                ? null
                : 'กรุณากรอกรหัสยืนยัน 6 หลัก',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: 'รหัสผ่านใหม่',
              prefixIcon: const Icon(Icons.lock_outline),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _showPassword ? 'ซ่อนรหัสผ่าน' : 'แสดงรหัสผ่าน',
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
            validator: (value) => (value?.length ?? 0) >= 8
                ? null
                : 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_showConfirmPassword,
            decoration: InputDecoration(
              labelText: 'ยืนยันรหัสผ่านใหม่',
              prefixIcon: const Icon(Icons.lock_reset),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _showConfirmPassword ? 'ซ่อนรหัสผ่าน' : 'แสดงรหัสผ่าน',
                onPressed: () => setState(
                  () => _showConfirmPassword = !_showConfirmPassword,
                ),
                icon: Icon(
                  _showConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
              ),
            ),
            validator: (value) => value == _passwordController.text
                ? null
                : 'รหัสผ่านทั้งสองช่องไม่ตรงกัน',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _submitting ? null : _confirmReset,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('ตั้งรหัสผ่านใหม่'),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: _submitting ? null : _requestCode,
              child: const Text('ส่งรหัสยืนยันอีกครั้ง'),
            ),
          ),
        ],
      ),
    );
  }
}
