import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../data/dummy_data.dart';
import '../main_layout.dart';
import '../report/report_issue_page.dart';
import '../label/label_print_page.dart';

class MachineDetailPage extends StatefulWidget {
  final Machine machine;
  const MachineDetailPage({super.key, required this.machine});

  @override
  State<MachineDetailPage> createState() => _MachineDetailPageState();
}

class _MachineDetailPageState extends State<MachineDetailPage> {
  late bool isMachineOn;
  late double plasticLevel;
  late double glassLevel;
  late double canLevel;

  // Requirement 4: Filter issues for this machine
  late List<IssueReportItem> machineIssues;
  bool isIssuesExpanded = false;

  @override
  void initState() {
    super.initState();
    isMachineOn = widget.machine.isOn;
    plasticLevel = widget.machine.plasticLevel;
    glassLevel = widget.machine.glassLevel;
    canLevel = widget.machine.canLevel;
    // กรองรายงานปัญหาเฉพาะเครื่องนี้
    machineIssues = mockIssueReports
        .where((r) => r.machineId == widget.machine.id)
        .toList();
  }

  void _collectWaste(String type, Function(double) updateState) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pop(context);
      setState(() => updateState(0.0));
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text("บันทึกข้อมูลสำเร็จ"),
            ],
          ),
          content: Text(
            "ทำการเก็บขยะประเภท '$type' เรียบร้อยแล้ว\nบันทึกลงฐานข้อมูลแล้ว",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("ปิด"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.print),
              label: const Text("พิมพ์ป้ายลาเบล"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => LabelPrintPage(
                      machineName: widget.machine.name,
                      preSelectedType: type,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  // Helper สำหรับนับแจ้งเตือน
  int get notificationCount => mockNotifications
      .where(
        (n) =>
            mockMachines.firstWhere((m) => m.id == n.machineId).caretakerId ==
            currentUser.id,
      )
      .length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.machine.name),
        // Requirement 5: ปุ่มพิมพ์ป้ายลาเบลทั่วไป ให้นำออก (actions ว่าง)
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนควบคุมเปิด-ปิด
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: isMachineOn ? Colors.teal : Colors.grey[800],
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'สถานะระบบ (System Status)',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isMachineOn ? 'กำลังทำงาน' : 'ปิดการทำงาน',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Transform.scale(
                      scale: 1.5,
                      child: Switch(
                        value: isMachineOn,
                        activeColor: Colors.white,
                        activeTrackColor: Colors.tealAccent,
                        onChanged: (val) => setState(() => isMachineOn = val),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Text(
              'ระดับปริมาณขยะ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            _buildBinLevel(
              'ขวดพลาสติก (PET)',
              plasticLevel,
              Colors.orange,
              (val) => plasticLevel = val,
            ),
            _buildBinLevel(
              'ขวดแก้ว (Glass)',
              glassLevel,
              Colors.blueAccent,
              (val) => glassLevel = val,
            ),
            _buildBinLevel(
              'กระป๋อง (Can)',
              canLevel,
              Colors.green,
              (val) => canLevel = val,
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.build),
                label: const Text('แจ้งซ่อม / รายงานปัญหา'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) =>
                        ReportIssuePage(machineName: widget.machine.name),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Requirement 4: ประวัติการแจ้งปัญหา (Expandable)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    const Icon(Icons.history_edu, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text(
                      'ประวัติการแจ้งปัญหา',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    // Counter Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${machineIssues.length}',
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                children: machineIssues.isEmpty
                    ? [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('ไม่มีประวัติการแจ้งปัญหา'),
                        ),
                      ]
                    : machineIssues
                          .map(
                            (issue) => ListTile(
                              title: Text(
                                issue.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('${issue.date} • ${issue.status}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // Show Detail Dialog
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(issue.title),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('วันที่: ${issue.date}'),
                                        Text(
                                          'สถานะ: ${issue.status == 'Resolved' ? 'แก้ไขแล้ว' : 'รอดำเนินการ'}',
                                          style: TextStyle(
                                            color: issue.status == 'Resolved'
                                                ? Colors.green
                                                : Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Divider(),
                                        const Text(
                                          'รายละเอียด:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(issue.description),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('ปิด'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                          .toList(),
              ),
            ),

            // ประวัติการเก็บขยะ (เดิม)
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'ประวัติการเก็บขยะล่าสุด',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _buildHistoryItem('15/01/2026', '10:30', 'พลาสติก', '3.2 kg'),
            _buildHistoryItem('14/01/2026', '16:00', 'แก้ว', '5.0 kg'),
            _buildHistoryItem('12/01/2026', '09:15', 'กระป๋อง', '2.1 kg'),
          ],
        ),
      ),
      // --- เพิ่ม NavigationBar ด้านล่าง ---
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (idx) {
          if (idx == 0) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainLayout(initialIndex: idx),
              ),
            );
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view),
            label: 'เครื่องคัดแยก',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'ประวัติ'),
          NavigationDestination(
            icon: Badge(
              label: Text('0'),
              child: const Icon(Icons.notifications),
            ),
            label: 'แจ้งเตือน',
          ),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'สถิติ'),
          NavigationDestination(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    String date,
    String time,
    String type,
    String weight,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: const Icon(Icons.history, color: Colors.grey),
        ),
        title: Text('$type - $weight'),
        subtitle: Text('$date • $time'),
        trailing: IconButton(
          icon: const Icon(Icons.print, color: Colors.blue),
          tooltip: 'พิมพ์ป้ายย้อนหลัง',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => LabelPrintPage(
                machineName: widget.machine.name,
                preSelectedType: type,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBinLevel(
    String label,
    double level,
    Color color,
    Function(double) updateState,
  ) {
    bool isFull = level >= 0.9;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isFull
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: isFull
          ? ExpansionTile(
              initiallyExpanded: true,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded, color: Colors.red),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${(level * 100).toInt()}%',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: level,
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text(
                      'สถานะ: เต็ม! กรุณาเก็บทันที',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      const Divider(),
                      const Text(
                        "ถังขยะเต็มแล้ว! กรุณากดปุ่มด้านล่างเพื่อยืนยันการเก็บและพิมพ์ป้าย",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          onPressed: () => _collectWaste(label, updateState),
                          icon: const Icon(Icons.cleaning_services),
                          label: const Text('เก็บขยะ (Collect Waste)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.delete_outline, color: color),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: level,
                              minHeight: 10,
                              backgroundColor: Colors.grey[200],
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        children: [
                          Text(
                            '${(level * 100).toInt()}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 30,
                            child: ElevatedButton(
                              onPressed: () =>
                                  _collectWaste(label, updateState),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              child: const Text('เก็บ'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

