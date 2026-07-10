import 'package:flutter/material.dart';
import 'dart:math';
import '../../data/dummy_data.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int _selectedPeriodIndex = 0;
  final List<String> _periods = ['วันนี้', 'สัปดาห์นี้', 'เดือนนี้', 'ปีนี้'];

  void _exportToPdf() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Export สำเร็จ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.picture_as_pdf, color: Colors.red, size: 50),
              SizedBox(height: 10),
              Text('ไฟล์รายงานถูกบันทึกแล้ว:\nDownload/Report_2024.pdf'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
    });
  }

  Map<String, dynamic> _getStatsData(int index) {
    switch (index) {
      case 0:
        return {'total': 12.5, 'plastic': 5.5, 'glass': 4.0, 'can': 3.0};
      case 1:
        return {'total': 85.0, 'plastic': 40.0, 'glass': 30.0, 'can': 15.0};
      case 2:
        return {'total': 320.0, 'plastic': 150.0, 'glass': 100.0, 'can': 70.0};
      case 3:
        return {
          'total': 1500.0,
          'plastic': 700.0,
          'glass': 500.0,
          'can': 300.0,
        };
      default:
        return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _getStatsData(_selectedPeriodIndex);
    // Reuse mockCollectionHistory for stats table
    final historyList = mockCollectionHistory.take(5).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('สถิติการคัดแยก')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: ToggleButtons(
                  isSelected: List.generate(
                    4,
                    (i) => i == _selectedPeriodIndex,
                  ),
                  onPressed: (int index) =>
                      setState(() => _selectedPeriodIndex = index),
                  borderRadius: BorderRadius.circular(30),
                  selectedColor: Colors.white,
                  fillColor: Colors.teal,
                  color: Colors.grey[600],
                  constraints: const BoxConstraints(
                    minHeight: 40,
                    minWidth: 80,
                  ),
                  children: _periods
                      .map(
                        (p) => Text(
                          p,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.teal, Colors.greenAccent],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'น้ำหนักขยะรวม (${_periods[_selectedPeriodIndex]})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${data['total']} kg',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMiniStatCard(
                        'พลาสติก',
                        '${data['plastic']}',
                        Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _buildMiniStatCard(
                        'แก้ว',
                        '${data['glass']}',
                        Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _buildMiniStatCard(
                        'กระป๋อง',
                        '${data['can']}',
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildBarChart(data),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.recycling, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('kg', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, dynamic> data) {
    final values = <double>[
      (data['plastic'] as num).toDouble(),
      (data['glass'] as num).toDouble(),
      (data['can'] as num).toDouble(),
    ];

    double maxVal = values.reduce(max);
    if (maxVal == 0) maxVal = 1;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildSingleBar(
            'พลาสติก',
            (data['plastic'] as num).toDouble(),
            maxVal,
            Colors.orange,
          ),
          _buildSingleBar(
            'แก้ว',
            (data['glass'] as num).toDouble(),
            maxVal,
            Colors.blue,
          ),
          _buildSingleBar(
            'กระป๋อง',
            (data['can'] as num).toDouble(),
            maxVal,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSingleBar(
    String label,
    double value,
    double maxVal,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${value.toInt()}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: (value / maxVal) * 120,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Color _getTypeColor(String type) {
    if (type == 'พลาสติก') return Colors.orange;
    if (type == 'แก้ว') return Colors.blue;
    return Colors.green;
  }
}

