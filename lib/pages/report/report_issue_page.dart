import 'package:flutter/material.dart';

class ReportIssuePage extends StatefulWidget {
  final String machineName;
  const ReportIssuePage({super.key, required this.machineName});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  String selectedIssue = 'เครื่องไม่ทำงาน';
  final List<String> issues = [
    'เครื่องไม่ทำงาน',
    'เซ็นเซอร์ผิดปกติ',
    'ถังขยะชำรุด',
    'ระบบไฟขัดข้อง',
    'อื่นๆ',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แจ้งซ่อม/รายงานปัญหา')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'เครื่อง: ${widget.machineName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            const Text(
              'หัวข้อปัญหา',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedIssue,
                  items: issues
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedIssue = val!),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'รายละเอียดเพิ่มเติม',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'อธิบายอาการหรือปัญหาที่พบ...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('ส่งข้อมูลสำเร็จ'),
                      content: const Text(
                        'เจ้าหน้าที่ได้รับเรื่องแจ้งซ่อมแล้ว',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(c);
                            Navigator.pop(context);
                          },
                          child: const Text('ตกลง'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('ส่งรายงาน'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

