import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
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
  late Machine _machine;
  late bool isMachineOn;
  late double plasticLevel;
  late double glassLevel;
  late double canLevel;

  // Requirement 4: Filter issues for this machine
  late List<IssueReportItem> machineIssues;
  List<CollectionHistoryItem> machineHistory = [];
  int notificationCount = 0;
  bool isIssuesExpanded = false;
  bool _updatingStatus = false;
  bool? _pendingStatus;
  StreamSubscription<ApiResource>? _cacheSubscription;

  bool get _displayedStatus => _pendingStatus ?? isMachineOn;
  bool get _canCollectWaste =>
      _machine.canOperate && !isMachineOn && !_updatingStatus;

  String get _machineStatusText {
    if (_updatingStatus) {
      return _pendingStatus == true
          ? 'กำลังเปิดรับข้อมูลจากเครื่อง…'
          : 'กำลังหยุดรับข้อมูลจากเครื่อง…';
    }
    return isMachineOn ? 'เปิดรับข้อมูลจากเครื่อง' : 'ปิดรับข้อมูลจากเครื่อง';
  }

  @override
  void initState() {
    super.initState();
    _machine = widget.machine;
    isMachineOn = _machine.isOn;
    plasticLevel = _machine.plasticLevel;
    glassLevel = _machine.glassLevel;
    canLevel = _machine.canLevel;
    machineIssues = [];
    _cacheSubscription = ApiService.cacheUpdates.where((resource) {
      return resource == ApiResource.issues ||
          resource == ApiResource.collections ||
          resource == ApiResource.notifications ||
          resource == ApiResource.machines;
    }).listen((resource) {
      if (resource == ApiResource.machines) {
        _loadMachine();
      } else {
        _loadDatabaseData();
      }
    });
    _loadMachine(forceRefresh: true);
    _loadDatabaseData(forceRefresh: true);
  }

  @override
  void dispose() {
    _cacheSubscription?.cancel();
    super.dispose();
  }

  void _applyMachine(Machine machine) {
    if (!mounted) return;
    setState(() {
      _machine = machine;
      isMachineOn = machine.isOn;
      plasticLevel = machine.plasticLevel;
      glassLevel = machine.glassLevel;
      canLevel = machine.canLevel;
    });
  }

  Future<void> _loadMachine({bool forceRefresh = false}) async {
    try {
      final machine = await ApiService.machineDetail(
        _machine.id,
        forceRefresh: forceRefresh,
      );
      _applyMachine(machine);
    } catch (error) {
      if (mounted && forceRefresh) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลดรายละเอียดเครื่องไม่สำเร็จ: $error')),
        );
      }
    }
  }

  Future<void> _setMachineStatus(bool value) async {
    if (!_machine.canOperate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'เฉพาะผู้ดูแลเครื่องเท่านั้นที่สามารถเปิดหรือปิดการรับข้อมูลได้',
          ),
        ),
      );
      return;
    }
    setState(() {
      _updatingStatus = true;
      _pendingStatus = value;
    });
    try {
      final machine = await ApiService.updateMachineStatus(_machine.id, value);
      _applyMachine(machine);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เปลี่ยนสถานะเครื่องไม่สำเร็จ: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingStatus = false;
          _pendingStatus = null;
        });
      }
    }
  }

  Future<void> _loadDatabaseData({bool forceRefresh = false}) async {
    try {
      final results = await Future.wait([
        ApiService.issues(forceRefresh: forceRefresh),
        ApiService.collections(),
        ApiService.notifications(),
      ]);
      if (!mounted) return;
      setState(() {
        machineIssues = (results[0] as List<IssueReportItem>)
            .where((item) => item.machineId == _machine.id)
            .toList();
        machineHistory = (results[1] as List<CollectionHistoryItem>)
            .where((item) => item.machineId == _machine.id)
            .toList();
        notificationCount = (results[2] as List<NotificationItem>)
            .where((item) => !item.isRead)
            .length;
      });
    } catch (_) {
      // แต่ละส่วนมีหน้ารวมสำหรับลองโหลดใหม่ จึงไม่บล็อกหน้ารายละเอียดเครื่อง
    }
  }

  Future<void> _collectWaste(
    String type,
    Function(double) updateState,
  ) async {
    if (!_machine.canOperate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เครื่องนี้อยู่ในโหมดดูอย่างเดียวสำหรับบัญชีของคุณ'),
        ),
      );
      return;
    }
    if (_updatingStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('กรุณารอให้การเปลี่ยนสถานะเครื่องเสร็จสิ้น')),
      );
      return;
    }
    if (isMachineOn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากดปิดเครื่องก่อนทำการเก็บขยะ')),
      );
      return;
    }

    final wasteType = switch (type) {
      'พลาสติก' => 'plastic',
      'แก้ว' => 'glass',
      'กระป๋อง' => 'can',
      _ => '',
    };
    final weight = switch (wasteType) {
      'plastic' => _machine.plasticWeight,
      'glass' => _machine.glassWeight,
      'can' => _machine.canWeight,
      _ => 0.0,
    };
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final requestedAt = DateTime.now();
    final labelCode =
        'LBL-${_machine.id}-${requestedAt.millisecondsSinceEpoch}';
    Map<String, dynamic> createdCollection;
    try {
      createdCollection = await ApiService.createCollection(
        _machine.id,
        wasteType,
        weight,
        labelCode: labelCode,
      );
    } catch (error) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกการเก็บขยะไม่สำเร็จ: $error')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pop(context);
    setState(() => updateState(0.0));
    final collectedAt =
        DateTime.tryParse('${createdCollection['collected_at']}')?.toLocal() ??
            requestedAt;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LabelPrintPage(
          machineName: _machine.name,
          preSelectedType: type,
          weightKg: weight,
          collectedAt: collectedAt,
          batchCode: '${createdCollection['label_code'] ?? labelCode}',
          collectionSaved: true,
        ),
      ),
    );
    if (mounted) {
      await Future.wait([
        _loadMachine(forceRefresh: true),
        _loadDatabaseData(forceRefresh: true),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_machine.name),
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
              color: _displayedStatus ? Colors.teal : Colors.grey[800],
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'การรับข้อมูลจากเครื่อง (Device Data)',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (_updatingStatus) ...[
                                const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Flexible(
                                child: Text(
                                  _machineStatusText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 1.5,
                      child: Switch(
                        value: _displayedStatus,
                        activeThumbColor: Colors.white,
                        activeTrackColor: Colors.tealAccent,
                        onChanged: _updatingStatus || !_machine.canOperate
                            ? null
                            : _setMachineStatus,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (!_machine.canOperate) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  border: Border.all(color: Colors.blueGrey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.visibility, color: Colors.blueGrey),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'โหมดดูอย่างเดียว · ผู้ดูแลเครื่อง: ${_machine.caretakerName.isEmpty ? 'ยังไม่กำหนด' : _machine.caretakerName}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (!_canCollectWaste) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ต้องกดปิดเครื่องและรอจนสถานะเป็น “ปิดรับข้อมูลจากเครื่อง” ก่อนจึงจะเก็บขยะได้',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_machine.canOperate && _canCollectWaste) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  border: Border.all(color: Colors.teal.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.timer_outlined, color: Colors.teal),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ระบบพักรับข้อมูลเป็นเวลา 30 นาที หาก ESP32 ยังส่งข้อมูลหลังครบเวลา เครื่องจะกลับมาออนไลน์อัตโนมัติ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            Text(
              'ระดับปริมาณขยะ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            _buildBinLevel(
              'พลาสติก',
              plasticLevel,
              Colors.green,
              (val) => plasticLevel = val,
            ),
            _buildBinLevel(
              'แก้ว',
              glassLevel,
              Colors.blueAccent,
              (val) => glassLevel = val,
            ),
            _buildBinLevel(
              'กระป๋อง',
              canLevel,
              Colors.orange,
              (val) => canLevel = val,
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.build),
                label: const Text('แจ้งซ่อม / รายงานปัญหา'),
                onPressed: _machine.canOperate
                    ? () async {
                        final created = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportIssuePage(
                              machineId: _machine.id,
                              machineName: _machine.name,
                            ),
                          ),
                        );
                        if (created == true) {
                          _loadDatabaseData(forceRefresh: true);
                        }
                      }
                    : null,
              ),
            ),

            const SizedBox(height: 16),

            // Requirement 4: ประวัติการแจ้งปัญหา (Expandable)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                onExpansionChanged: (expanded) {
                  if (expanded) _loadDatabaseData(forceRefresh: true);
                },
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
                            subtitle:
                                Text('${issue.date} • ${issue.statusLabel}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await _loadDatabaseData(forceRefresh: true);
                              if (!context.mounted) return;
                              final latest = machineIssues.firstWhere(
                                (item) => item.id == issue.id,
                                orElse: () => issue,
                              );
                              // Show Detail Dialog
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(latest.title),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('วันที่: ${latest.date}'),
                                      Text(
                                        'สถานะ: ${latest.statusLabel}',
                                        style: TextStyle(
                                          color: latest.status == 'Completed' ||
                                                  latest.status == 'Resolved'
                                              ? Colors.green
                                              : latest.status == 'In Progress'
                                                  ? Colors.blue
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
                                      Text(latest.description),
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
            if (machineHistory.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('ยังไม่มีประวัติการเก็บขยะของเครื่องนี้'),
              )
            else
              ...machineHistory.take(5).map(_buildHistoryItem),
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
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.grid_view),
            label: 'เครื่องคัดแยก',
          ),
          const NavigationDestination(
              icon: Icon(Icons.history), label: 'ประวัติ'),
          NavigationDestination(
            icon: Badge(
              label: Text('$notificationCount'),
              isLabelVisible: notificationCount > 0,
              child: const Icon(Icons.notifications),
            ),
            label: 'แจ้งเตือน',
          ),
          const NavigationDestination(
            icon: Icon(Icons.description),
            label: 'รายงาน',
          ),
          const NavigationDestination(
              icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(CollectionHistoryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: const Icon(Icons.history, color: Colors.grey),
        ),
        title: Text('${item.type} - ${item.weight}'),
        subtitle: Text('${item.date} • ${item.time}'),
        trailing: IconButton(
          icon: const Icon(Icons.print, color: Colors.blue),
          tooltip: 'พิมพ์ป้ายย้อนหลัง',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => LabelPrintPage(
                machineName: _machine.name,
                preSelectedType: item.type,
                weightKg: double.tryParse(item.weight.split(' ').first),
                collectedAt: parseAppDate(item.date),
                batchCode: 'COL-${item.id}',
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
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
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
                    style: const TextStyle(
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
                          onPressed: _canCollectWaste
                              ? () => _collectWaste(label, updateState)
                              : null,
                          icon: const Icon(Icons.cleaning_services),
                          label: Text(
                            _canCollectWaste
                                ? 'เก็บขยะ (Collect Waste)'
                                : 'กรุณาปิดเครื่องก่อนเก็บขยะ',
                          ),
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
                          color: color.withValues(alpha: 0.1),
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
                              onPressed: _canCollectWaste
                                  ? () => _collectWaste(label, updateState)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              child: Text(
                                _canCollectWaste ? 'เก็บ' : 'ปิดเครื่องก่อน',
                              ),
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
