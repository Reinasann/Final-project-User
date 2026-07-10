import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../data/dummy_data.dart';

class LabelPrintPage extends StatefulWidget {
  final String machineName;
  final String? preSelectedType;

  const LabelPrintPage({
    super.key,
    this.machineName = 'Unknown Machine',
    this.preSelectedType,
  });

  @override
  State<LabelPrintPage> createState() => _LabelPrintPageState();
}

class _LabelPrintPageState extends State<LabelPrintPage> {
  late String selectedType;
  final List<String> wasteTypes = [
    'พลาสติก (PET)',
    'ขวดแก้ว (Glass)',
    'กระป๋อง (Can)',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedType != null) {
      if (widget.preSelectedType!.contains('พลาสติก'))
        selectedType = wasteTypes[0];
      else if (widget.preSelectedType!.contains('แก้ว'))
        selectedType = wasteTypes[1];
      else if (widget.preSelectedType!.contains('กระป๋อง'))
        selectedType = wasteTypes[2];
      else
        selectedType = wasteTypes[0];
    } else {
      selectedType = wasteTypes[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('พิมพ์ป้ายลาเบล')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ประเภทขยะที่จะพิมพ์',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
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
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(Icons.lock, color: Colors.grey, size: 20),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              'ตัวอย่างป้าย (Preview)',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),

            Center(
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
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
                      child: const Center(
                        child: Icon(Icons.qr_code_2, size: 80),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'BATCH-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLabelRow('Machine:', widget.machineName),
                    _buildLabelRow('Type:', selectedType),
                    _buildLabelRow('Weight:', '12.5 kg (Est.)'),
                    _buildLabelRow(
                      'Date:',
                      '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    ),
                    _buildLabelRow('Collector:', currentUser.name),
                    const SizedBox(height: 16),

                    // เส้นประจำลอง
                    Row(
                      children: List.generate(
                        30,
                        (index) => Expanded(
                          child: Container(
                            color: index % 2 == 0
                                ? Colors.black38
                                : Colors.transparent,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Text(
                      'SCAN FOR TRACKING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กำลังส่งข้อมูลไปยังเครื่องพิมพ์...'),
                    ),
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text('สั่งพิมพ์ (Print Label)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

