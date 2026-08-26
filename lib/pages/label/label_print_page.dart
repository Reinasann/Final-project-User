import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../services/label_pdf_service.dart';
import '../../services/session_service.dart';

enum _LabelOutputType { printer, pdf }

class LabelPrintPage extends StatefulWidget {
  final String machineName;
  final String? preSelectedType;
  final double? weightKg;
  final DateTime? collectedAt;
  final String? batchCode;
  final bool collectionSaved;

  const LabelPrintPage({
    super.key,
    this.machineName = 'ไม่ระบุเครื่อง',
    this.preSelectedType,
    this.weightKg,
    this.collectedAt,
    this.batchCode,
    this.collectionSaved = false,
  });

  @override
  State<LabelPrintPage> createState() => _LabelPrintPageState();
}

class _LabelPrintPageState extends State<LabelPrintPage> {
  late final String selectedType;
  late final DateTime collectedAt;
  late final String batchCode;
  bool _isProcessing = false;

  static const wasteTypes = [
    'พลาสติก (PET)',
    'ขวดแก้ว (Glass)',
    'กระป๋อง (Can)',
  ];

  double get weightKg => widget.weightKg ?? 0;

  @override
  void initState() {
    super.initState();
    collectedAt = widget.collectedAt ?? DateTime.now();
    batchCode = widget.batchCode ??
        'LBL-${DateFormat('yyyyMMdd-HHmmss').format(collectedAt)}';
    if (widget.preSelectedType?.contains('แก้ว') == true) {
      selectedType = wasteTypes[1];
    } else if (widget.preSelectedType?.contains('กระป๋อง') == true) {
      selectedType = wasteTypes[2];
    } else {
      selectedType = wasteTypes[0];
    }
  }

  Future<void> _choosePrintOutput() async {
    final output = await showModalBottomSheet<_LabelOutputType>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'เลือกรูปแบบการพิมพ์',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'เลือกส่งลาเบลไปยังเครื่องพิมพ์ หรือบันทึกเป็นไฟล์ PDF',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                _outputOption(
                  icon: Icons.print_outlined,
                  color: Colors.blue,
                  title: 'พิมพ์ด้วยเครื่องพิมพ์',
                  subtitle: 'เปิดหน้าต่างเลือกเครื่องพิมพ์และขนาดกระดาษ',
                  onTap: () => Navigator.pop(
                    context,
                    _LabelOutputType.printer,
                  ),
                ),
                const SizedBox(height: 10),
                _outputOption(
                  icon: Icons.picture_as_pdf_outlined,
                  color: Colors.red,
                  title: 'พิมพ์เป็น PDF',
                  subtitle: 'บันทึก ดาวน์โหลด หรือแชร์ไฟล์ลาเบล PDF',
                  onTap: () => Navigator.pop(context, _LabelOutputType.pdf),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (output == null || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      if (output == _LabelOutputType.printer) {
        await LabelPdfService.printToPrinter(
          batchCode: batchCode,
          machineName: widget.machineName,
          wasteType: selectedType,
          weightKg: weightKg,
          collectedAt: collectedAt,
          collectorName: currentUser.name,
        );
      } else {
        await LabelPdfService.exportPdf(
          batchCode: batchCode,
          machineName: widget.machineName,
          wasteType: selectedType,
          weightKg: weightKg,
          collectedAt: collectedAt,
          collectorName: currentUser.name,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            output == _LabelOutputType.printer
                ? 'ส่งลาเบลไปยังระบบเครื่องพิมพ์แล้ว'
                : 'สร้างไฟล์ลาเบล PDF แล้ว',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถพิมพ์ลาเบลได้: $error')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _outputOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('พิมพ์ลาเบล')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.collectionSaved) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'บันทึกการเก็บขยะลงฐานข้อมูลแล้ว กรุณาพิมพ์ลาเบล',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            const Text(
              'ประเภทขยะที่เก็บ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedType,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text('ตัวอย่างลาเบล', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 310,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SMART RECYCLE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Icon(Icons.recycling, size: 20),
                      ],
                    ),
                    const Divider(thickness: 2, color: Colors.black),
                    const SizedBox(height: 8),
                    Container(
                      height: 100,
                      width: 100,
                      color: Colors.black12,
                      child:
                          const Center(child: Icon(Icons.qr_code_2, size: 80)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      batchCode,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLabelRow('เครื่องคัดแยก', widget.machineName),
                    _buildLabelRow('ประเภทขยะ', selectedType),
                    _buildLabelRow(
                      'น้ำหนักสุทธิ',
                      '${weightKg.toStringAsFixed(2)} กก.',
                    ),
                    _buildLabelRow('วันที่เก็บ', formatAppDate(collectedAt)),
                    _buildLabelRow(
                      'เวลา',
                      '${DateFormat('HH:mm').format(collectedAt)} น.',
                    ),
                    _buildLabelRow('ผู้เก็บขยะ', currentUser.name),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.black38),
                    const Text(
                      'สแกน QR Code เพื่อตรวจสอบข้อมูล',
                      style:
                          TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isProcessing ? null : _choosePrintOutput,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.print),
                label: Text(
                  _isProcessing ? 'กำลังเตรียมลาเบล…' : 'พิมพ์ลาเบล',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
