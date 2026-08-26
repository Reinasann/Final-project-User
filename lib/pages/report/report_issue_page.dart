import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../widgets/skeleton_loading.dart';

class ReportIssuePage extends StatefulWidget {
  final String machineId;
  final String machineName;

  const ReportIssuePage({
    super.key,
    required this.machineId,
    required this.machineName,
  });

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  late Future<List<Map<String, dynamic>>> _categoriesFuture;
  final _descriptionController = TextEditingController();
  int? _categoryId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ApiService.issueCategories();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกหัวข้อปัญหา')),
      );
      return;
    }
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกรายละเอียดปัญหา')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await ApiService.createIssue(
        widget.machineId,
        _categoryId!,
        description,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ส่งข้อมูลสำเร็จ'),
          content: const Text(
            'บันทึกรายการแจ้งปัญหาลงฐานข้อมูลแล้ว ผู้ดูแลสามารถตรวจสอบได้ทันที',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ส่งรายงานไม่สำเร็จ: $error')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แจ้งซ่อม / รายงานปัญหา')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppSkeletonLoading(layout: AppSkeletonLayout.form);
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton.icon(
                onPressed: () => setState(
                  () => _categoriesFuture =
                      ApiService.issueCategories(forceRefresh: true),
                ),
                icon: const Icon(Icons.refresh),
                label: Text('โหลดหัวข้อไม่สำเร็จ: ${snapshot.error}'),
              ),
            );
          }
          final categories = snapshot.data ?? const [];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'เครื่อง: ${widget.machineName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'หัวข้อปัญหา',
                    border: OutlineInputBorder(),
                  ),
                  items: categories
                      .map(
                        (item) => DropdownMenuItem(
                          value: item['id'] as int,
                          child: Text('${item['name']}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _categoryId = value),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'รายละเอียดเพิ่มเติม',
                    hintText: 'อธิบายอาการหรือปัญหาที่พบ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _sending ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: const Text('ส่งรายงาน'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
