import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../data/dummy_data.dart';
import '../label/label_print_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _searchQuery = '';
  String? _selectedMachine;
  DateTime? _startDate;
  DateTime? _endDate;

  // -----------------------------------------------------------
  // ฟังก์ชันสำหรับเลือกสีตามประเภทขยะ (เพิ่มส่วนนี้เข้ามา)
  // -----------------------------------------------------------
  Color _getTypeColor(String type) {
    if (type.contains('Plastic') || type.contains('PET') || type.contains('พลาสติก')) {
      return Colors.orange;
    } else if (type.contains('Glass') || type.contains('แก้ว')) {
      return Colors.blueAccent;
    } else if (type.contains('Can') || type.contains('กระป๋อง')) {
      return Colors.green;
    }
    return Colors.grey; // สีสำรอง
  }

  @override
  Widget build(BuildContext context) {
    // Filter Logic
    List<CollectionHistoryItem> filteredHistory = mockCollectionHistory.where((item) {
      bool matchesSearch = item.machineName.contains(_searchQuery) || item.type.contains(_searchQuery);
      bool matchesMachine = _selectedMachine == null || _selectedMachine == 'All' || item.machineName == _selectedMachine;

      bool matchesDate = true;
      if (_startDate != null && _endDate != null) {
        DateTime itemDate = DateTime.parse(item.date);
        matchesDate = itemDate.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
            itemDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }

      return matchesSearch && matchesMachine && matchesDate;
    }).toList();

    // Unique machines for dropdown
    final machinesList = mockCollectionHistory.map((e) => e.machineName).toSet().toList();

    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติการเก็บขยะ')),
      body: Column(
        children: [
          // -------------------------------------------------------
          // 1. Filters Section
          // -------------------------------------------------------
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'ค้นหา...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedMachine,
                          hint: const Text('เลือกเครื่อง'),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10),
                          ),
                          items: ['All', ...machinesList]
                              .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e == 'All' ? 'ทุกเครื่อง' : e),
                                  ))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedMachine = val),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.date_range),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2023),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = picked.start;
                              _endDate = picked.end;
                            });
                          }
                        },
                      ),
                      if (_startDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () => setState(() {
                            _startDate = null;
                            _endDate = null;
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // -------------------------------------------------------
          // 2. Data Display Section (ListView + Card + Custom Colors)
          // -------------------------------------------------------
          Expanded(
            child: filteredHistory.isEmpty
                ? const Center(child: Text('ไม่พบข้อมูล'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final item = filteredHistory[index];
                      
                      // เรียกใช้ฟังก์ชันดึงสี (ส้ม/ฟ้า/เขียว)
                      final Color typeColor = _getTypeColor(item.type);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // ส่วนข้อมูลหลัก (ซ้าย)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ชื่อเครื่อง
                                    Text(
                                      item.machineName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // ประเภท (ใส่สี) และ น้ำหนัก
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            // ใช้สีที่ได้จากฟังก์ชัน + ความโปร่งแสง
                                            color: typeColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: typeColor),
                                          ),
                                          child: Text(
                                            item.type,
                                            style: TextStyle(
                                              fontSize: 12, 
                                              fontWeight: FontWeight.bold,
                                              color: typeColor, // ใช้สีตัวอักษรตามประเภท
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'น้ำหนัก ${item.weight}',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    
                                    // วันที่และเวลา
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${item.date}  |  ${item.time}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // ส่วนปุ่ม Action (ขวา)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.print, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (c) => LabelPrintPage(
                                          machineName: item.machineName,
                                          preSelectedType: item.type,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

