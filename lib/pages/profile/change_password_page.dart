import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _oldVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;
  bool _saving = false;

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newPassword.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รหัสผ่านใหม่และการยืนยันไม่ตรงกัน')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.changePassword(_oldPassword.text, _newPassword.text);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เปลี่ยนรหัสผ่านในฐานข้อมูลสำเร็จ')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เปลี่ยนรหัสผ่านไม่สำเร็จ: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(
    String label,
    bool visible,
    VoidCallback toggle,
  ) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        tooltip: visible ? 'ซ่อนรหัสผ่าน' : 'แสดงรหัสผ่าน',
        onPressed: toggle,
        icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เปลี่ยนรหัสผ่าน')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _oldPassword,
                obscureText: !_oldVisible,
                decoration: _decoration(
                  'รหัสผ่านปัจจุบัน',
                  _oldVisible,
                  () => setState(() => _oldVisible = !_oldVisible),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'กรุณากรอกรหัสผ่านปัจจุบัน'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPassword,
                obscureText: !_newVisible,
                decoration: _decoration(
                  'รหัสผ่านใหม่',
                  _newVisible,
                  () => setState(() => _newVisible = !_newVisible),
                ),
                validator: (value) => value == null || value.length < 8
                    ? 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPassword,
                obscureText: !_confirmVisible,
                decoration: _decoration(
                  'ยืนยันรหัสผ่านใหม่',
                  _confirmVisible,
                  () => setState(() => _confirmVisible = !_confirmVisible),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'กรุณายืนยันรหัสผ่านใหม่'
                    : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ยืนยัน'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
