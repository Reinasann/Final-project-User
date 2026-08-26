import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/date_range_preset.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/pdf_report_service.dart';
import '../../widgets/skeleton_loading.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportData {
  final List<Machine> machines;
  final List<CollectionHistoryItem> collections;
  final List<IssueReportItem> issues;

  const _ReportData(this.machines, this.collections, this.issues);
}

class _ReportPageState extends State<ReportPage> {
  late Future<_ReportData> _future;
  String _machineId = 'all';
  String _wasteType = 'all';
  String _rangePreset = '7d';
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _exportingPdf = false;
  StreamSubscription<ApiResource>? _cacheSubscription;

  @override
  void initState() {
    super.initState();
    _cacheSubscription = ApiService.cacheUpdates.where((resource) {
      return resource == ApiResource.machines ||
          resource == ApiResource.collections ||
          resource == ApiResource.issues;
    }).listen((_) {
      if (mounted) setState(_reload);
    });
    _reload();
  }

  void _reload({bool forceRefresh = false}) {
    _future = Future.wait([
      ApiService.machines(forceRefresh: forceRefresh),
      ApiService.collections(forceRefresh: forceRefresh),
      ApiService.issues(forceRefresh: forceRefresh),
    ]).then(
      (values) => _ReportData(
        values[0] as List<Machine>,
        values[1] as List<CollectionHistoryItem>,
        values[2] as List<IssueReportItem>,
      ),
    );
  }

  @override
  void dispose() {
    _cacheSubscription?.cancel();
    super.dispose();
  }

  double _weight(CollectionHistoryItem item) {
    return double.tryParse(item.weight.split(' ').first) ?? 0;
  }

  DateTime? _collectionDate(CollectionHistoryItem item) {
    final value = parseAppDate(item.date);
    return value == null ? null : DateTime(value.year, value.month, value.day);
  }

  DateTimeRange _selectedDateRange(List<CollectionHistoryItem> collections) {
    if (_customStartDate != null && _customEndDate != null) {
      return DateTimeRange(start: _customStartDate!, end: _customEndDate!);
    }
    final dates =
        collections.map(_collectionDate).whereType<DateTime>().toList()..sort();
    final now = DateTime.now();
    final end =
        dates.isEmpty ? DateTime(now.year, now.month, now.day) : dates.last;
    return appPresetDateRange(_rangePreset, end);
  }

  List<DateTime> _datePoints(DateTimeRange range) {
    final days = range.end.difference(range.start).inDays + 1;
    return List.generate(days, (index) {
      return range.start.add(Duration(days: index));
    });
  }

  bool _isInRange(DateTime? value, DateTimeRange range) {
    if (value == null) return false;
    return !value.isBefore(range.start) && !value.isAfter(range.end);
  }

  List<_TrendSeries> _trendSeries(
    _ReportData data,
    List<DateTime> dates,
  ) {
    const colors = [
      Color(0xFF2DD4BF),
      Color(0xFF60A5FA),
      Color(0xFFA78BFA),
      Color(0xFFF59E0B),
      Color(0xFFFB7185),
      Color(0xFF34D399),
    ];
    final machines = _machineId == 'all'
        ? data.machines
        : data.machines.where((machine) => machine.id == _machineId).toList();
    return List.generate(machines.length, (index) {
      final machine = machines[index];
      final values = dates.map((date) {
        return data.collections.where((item) {
          final itemDate = _collectionDate(item);
          return item.machineId == machine.id &&
              itemDate == date &&
              (_wasteType == 'all' || item.type == _wasteType);
        }).fold<double>(0, (sum, item) => sum + _weight(item));
      }).toList();
      return _TrendSeries(machine.name, colors[index % colors.length], values);
    });
  }

  String _formatDate(DateTime date) {
    return formatAppDate(date);
  }

  Future<void> _pickDateRange(
    List<CollectionHistoryItem> collections,
  ) async {
    final initialRange = _selectedDateRange(collections);
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          initialRange.end.isAfter(DateTime.now()) ? null : initialRange,
      helpText: 'เลือกช่วงวันที่สำหรับกราฟ',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
      saveText: 'บันทึก',
    );
    if (result != null) {
      setState(() {
        _customStartDate = result.start;
        _customEndDate = result.end;
      });
    }
  }

  void _selectPreset(String preset) {
    setState(() {
      _rangePreset = preset;
      _customStartDate = null;
      _customEndDate = null;
    });
  }

  String _machineLabel(_ReportData data) {
    if (_machineId == 'all') return 'ทุกเครื่อง';
    for (final machine in data.machines) {
      if (machine.id == _machineId) return machine.name;
    }
    return _machineId;
  }

  String get _wasteTypeLabel => _wasteType == 'all' ? 'ทุกประเภท' : _wasteType;

  Map<String, double> _collectionTotals(
    List<CollectionHistoryItem> collections,
  ) {
    double sumByType(String type) => collections
        .where((item) => item.type == type)
        .fold<double>(0, (sum, item) => sum + _weight(item));
    return {
      'total': collections.fold<double>(
        0,
        (sum, item) => sum + _weight(item),
      ),
      'plastic': sumByType('พลาสติก'),
      'glass': sumByType('แก้ว'),
      'can': sumByType('กระป๋อง'),
    };
  }

  String _colorHex(Color color) {
    final value = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${value.substring(2).toUpperCase()}';
  }

  Future<PdfReportSections?> _selectPdfSections() {
    var summary = true;
    var chart = true;
    var collectionHistory = true;
    var issues = true;
    return showModalBottomSheet<PdfReportSections>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final hasSelection = summary || chart || collectionHistory || issues;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'เลือกส่วนที่ต้องการส่งออก PDF',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'เอกสารจะใช้ตัวกรองเครื่อง ประเภทขยะ และช่วงวันที่ปัจจุบัน',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: summary,
                    onChanged: (value) =>
                        setModalState(() => summary = value ?? false),
                    title: const Text('ข้อมูลสรุป'),
                    subtitle: const Text(
                      'น้ำหนักรวม จำนวนครั้ง และสัดส่วนแต่ละประเภท',
                    ),
                    secondary: const Icon(Icons.dashboard_outlined),
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                  CheckboxListTile(
                    value: chart,
                    onChanged: (value) =>
                        setModalState(() => chart = value ?? false),
                    title: const Text('กราฟปริมาณขยะที่เก็บแล้ว'),
                    subtitle: const Text('กราฟเส้นแยกตามเครื่องคัดแยก'),
                    secondary: const Icon(Icons.show_chart),
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                  CheckboxListTile(
                    value: collectionHistory,
                    onChanged: (value) => setModalState(
                      () => collectionHistory = value ?? false,
                    ),
                    title: const Text('ประวัติการเก็บขยะ'),
                    subtitle:
                        const Text('ตารางวัน เวลา เครื่อง ประเภท และน้ำหนัก'),
                    secondary: const Icon(Icons.table_rows_outlined),
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                  CheckboxListTile(
                    value: issues,
                    onChanged: (value) =>
                        setModalState(() => issues = value ?? false),
                    title: const Text('รายการแจ้งปัญหา'),
                    subtitle: const Text('ตารางปัญหาที่ผู้ใช้งานรายนี้แจ้ง'),
                    secondary: const Icon(Icons.report_problem_outlined),
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: hasSelection
                          ? () => Navigator.pop(
                                context,
                                PdfReportSections(
                                  summary: summary,
                                  chart: chart,
                                  collectionHistory: collectionHistory,
                                  issues: issues,
                                ),
                              )
                          : null,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('สร้างและส่งออก PDF'),
                    ),
                  ),
                  if (!hasSelection)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text(
                          'กรุณาเลือกอย่างน้อย 1 ส่วน',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportPdf({
    required _ReportData data,
    required DateTimeRange dateRange,
    required List<DateTime> chartDates,
    required List<_TrendSeries> trendSeries,
    required List<CollectionHistoryItem> collections,
    required List<IssueReportItem> issues,
  }) async {
    final sections = await _selectPdfSections();
    if (sections == null || !sections.hasSelection || !mounted) return;
    setState(() => _exportingPdf = true);
    try {
      await PdfReportService.exportUserCollectionReport(
        periodLabel:
            '${_formatDate(dateRange.start)} - ${_formatDate(dateRange.end)}',
        machineLabel: _machineLabel(data),
        wasteTypeLabel: _wasteTypeLabel,
        totals: _collectionTotals(collections),
        history: collections,
        issues: issues,
        chartDates: chartDates,
        chartSeries: trendSeries.map((item) {
          return PdfChartSeries(
            name: item.name,
            colorHex: _colorHex(item.color),
            values: item.values,
          );
        }).toList(),
        sections: sections,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถสร้าง PDF ได้: $error')),
      );
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  String _statusLabel(String status) {
    return switch (status) {
      'Waiting' => 'รอดำเนินการ',
      'In Progress' => 'กำลังดำเนินการ',
      'Completed' || 'Resolved' => 'เสร็จสิ้น',
      _ => status,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงาน'),
        actions: [
          IconButton(
            tooltip: 'โหลดข้อมูลใหม่',
            onPressed: () => setState(() => _reload(forceRefresh: true)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_ReportData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppSkeletonLoading(layout: AppSkeletonLayout.report);
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'โหลดรายงานจากฐานข้อมูลไม่สำเร็จ\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () =>
                          setState(() => _reload(forceRefresh: true)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final dateRange = _selectedDateRange(data.collections);
          final chartDates = _datePoints(dateRange);
          final trendSeries = _trendSeries(data, chartDates);
          final collections = data.collections.where((item) {
            final machineMatches =
                _machineId == 'all' || item.machineId == _machineId;
            final wasteMatches = _wasteType == 'all' || item.type == _wasteType;
            final dateMatches = _isInRange(_collectionDate(item), dateRange);
            return machineMatches && wasteMatches && dateMatches;
          }).toList();
          final issues = data.issues
              .where(
                (item) =>
                    (_machineId == 'all' || item.machineId == _machineId) &&
                    _isInRange(parseAppDate(item.date), dateRange),
              )
              .toList();
          final totalWeight = collections.fold<double>(
            0,
            (sum, item) => sum + _weight(item),
          );
          final openIssues = issues
              .where(
                (item) =>
                    item.status != 'Completed' && item.status != 'Resolved',
              )
              .length;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _reload(forceRefresh: true));
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _WasteTrendCard(
                  machines: data.machines,
                  machineId: _machineId,
                  wasteType: _wasteType,
                  rangePreset:
                      _customStartDate == null ? _rangePreset : 'custom',
                  rangeLabel:
                      '${_formatDate(dateRange.start)} - ${_formatDate(dateRange.end)}',
                  dates: chartDates,
                  series: trendSeries,
                  onMachineChanged: (value) =>
                      setState(() => _machineId = value),
                  onWasteTypeChanged: (value) =>
                      setState(() => _wasteType = value),
                  onPresetSelected: _selectPreset,
                  onDateRangePressed: () => _pickDateRange(data.collections),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _exportingPdf
                        ? null
                        : () => _exportPdf(
                              data: data,
                              dateRange: dateRange,
                              chartDates: chartDates,
                              trendSeries: trendSeries,
                              collections: collections,
                              issues: issues,
                            ),
                    icon: _exportingPdf
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.picture_as_pdf),
                    label: Text(
                      _exportingPdf ? 'กำลังสร้าง PDF...' : 'ส่งออกเป็น PDF',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.scale,
                        label: 'น้ำหนักที่เก็บรวม',
                        value: '${totalWeight.toStringAsFixed(2)} กก.',
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.receipt_long,
                        label: 'จำนวนครั้งที่เก็บ',
                        value: '${collections.length} ครั้ง',
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  icon: Icons.build_circle_outlined,
                  label: 'ปัญหาที่ยังไม่เสร็จ',
                  value: '$openIssues รายการ',
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  'ประวัติการเก็บล่าสุด',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (collections.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('ไม่พบข้อมูล')),
                    ),
                  )
                else
                  ...collections.take(10).map(
                        (item) => Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.recycling),
                            ),
                            title: Text('${item.type} • ${item.weight}'),
                            subtitle: Text(
                              '${item.machineName}\n'
                              '${item.date} เวลา ${item.time} น.',
                            ),
                            isThreeLine: true,
                          ),
                        ),
                      ),
                const SizedBox(height: 24),
                Text(
                  'รายการแจ้งปัญหา',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (issues.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('ไม่มีรายการแจ้งปัญหา')),
                    ),
                  )
                else
                  ...issues.take(10).map(
                        (item) => Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.report_problem,
                              color: Colors.orange,
                            ),
                            title: Text(item.title),
                            subtitle: Text('${item.description}\n${item.date}'),
                            trailing: Chip(
                              label: Text(_statusLabel(item.status)),
                            ),
                            isThreeLine: true,
                          ),
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

class _TrendSeries {
  final String name;
  final Color color;
  final List<double> values;

  const _TrendSeries(this.name, this.color, this.values);
}

class _WasteTrendCard extends StatelessWidget {
  final List<Machine> machines;
  final String machineId;
  final String wasteType;
  final String rangePreset;
  final String rangeLabel;
  final List<DateTime> dates;
  final List<_TrendSeries> series;
  final ValueChanged<String> onMachineChanged;
  final ValueChanged<String> onWasteTypeChanged;
  final ValueChanged<String> onPresetSelected;
  final VoidCallback onDateRangePressed;

  const _WasteTrendCard({
    required this.machines,
    required this.machineId,
    required this.wasteType,
    required this.rangePreset,
    required this.rangeLabel,
    required this.dates,
    required this.series,
    required this.onMachineChanged,
    required this.onWasteTypeChanged,
    required this.onPresetSelected,
    required this.onDateRangePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final filters = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth < 520
                          ? constraints.maxWidth
                          : 190,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('waste-$wasteType'),
                        initialValue: wasteType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'ประเภทขยะ',
                          prefixIcon: Icon(Icons.delete_outline),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('ทุกประเภท'),
                          ),
                          DropdownMenuItem(
                            value: 'พลาสติก',
                            child: Text('พลาสติก'),
                          ),
                          DropdownMenuItem(value: 'แก้ว', child: Text('แก้ว')),
                          DropdownMenuItem(
                            value: 'กระป๋อง',
                            child: Text('กระป๋อง'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) onWasteTypeChanged(value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth < 520
                          ? constraints.maxWidth
                          : 220,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('machine-$machineId'),
                        initialValue: machineId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'เครื่องคัดแยก',
                          prefixIcon: Icon(Icons.smart_toy_outlined),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('ทุกเครื่อง'),
                          ),
                          ...machines.map(
                            (machine) => DropdownMenuItem(
                              value: machine.id,
                              child: Text(
                                machine.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) onMachineChanged(value);
                        },
                      ),
                    ),
                  ],
                );
                if (constraints.maxWidth < 760) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _TrendHeading(),
                      const SizedBox(height: 14),
                      filters,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: _TrendHeading()),
                    filters,
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.date_range_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text('ช่วงวันที่ $rangeLabel')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: appDateRangePresets.map((preset) {
                        final selected = rangePreset == preset.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(preset.label),
                            selected: selected,
                            onSelected: (_) => preset.isCustom
                                ? onDateRangePressed()
                                : onPresetSelected(preset.key),
                            selectedColor: const Color(0xFF2563EB),
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : null,
                              fontWeight: FontWeight.w600,
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _WasteLineChartPainter(dates, series),
                    ),
                  ),
                  if (series.isEmpty)
                    const Center(child: Text('ไม่มีข้อมูลสำหรับแสดงกราฟ')),
                ],
              ),
            ),
            const Divider(),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 18,
                runSpacing: 8,
                children: series.map((item) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 26,
                        height: 4,
                        decoration: BoxDecoration(
                          color: item.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(item.name, style: const TextStyle(fontSize: 12)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendHeading extends StatelessWidget {
  const _TrendHeading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ปริมาณขยะที่เก็บแล้ว',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 3),
        Text(
          'เฉพาะรายการที่ผู้ใช้งานปัจจุบันเป็นผู้เก็บ',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _WasteLineChartPainter extends CustomPainter {
  final List<DateTime> dates;
  final List<_TrendSeries> series;

  const _WasteLineChartPainter(this.dates, this.series);

  @override
  void paint(Canvas canvas, Size size) {
    const padding = EdgeInsets.fromLTRB(52, 16, 12, 38);
    final plotWidth = size.width - padding.left - padding.right;
    final plotHeight = size.height - padding.top - padding.bottom;
    if (plotWidth <= 0 || plotHeight <= 0) return;

    final values = series.expand((item) => item.values);
    final maximum = values.isEmpty
        ? 0.0
        : values.reduce((current, next) => current > next ? current : next);
    final yMaximum = maximum <= 10 ? 10.0 : (maximum / 10).ceil() * 10.0;
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    for (var index = 0; index <= 4; index++) {
      final y = padding.top + (plotHeight / 4) * index;
      _drawDashedLine(
        canvas,
        Offset(padding.left, y),
        Offset(size.width - padding.right, y),
        gridPaint,
      );
      final value = yMaximum - (yMaximum / 4) * index;
      _drawText(
        canvas,
        '${_compact(value)} กก.',
        Offset(padding.left - 8, y),
        alignment: TextAlign.right,
        anchorRight: true,
      );
    }

    if (dates.isNotEmpty) {
      final step = dates.length <= 5 ? 1 : ((dates.length - 1) / 4).ceil();
      for (var index = 0; index < dates.length; index++) {
        if (index != 0 && index != dates.length - 1 && index % step != 0) {
          continue;
        }
        final x = _xPosition(index, dates.length, padding.left, plotWidth);
        final date = dates[index];
        _drawText(
          canvas,
          formatAppDate(date),
          Offset(x, size.height - padding.bottom + 14),
          alignment: TextAlign.center,
        );
      }
    }

    for (final item in series) {
      if (item.values.isEmpty) continue;
      final linePaint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final pointPaint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;
      final path = Path();
      for (var index = 0; index < item.values.length; index++) {
        final x = _xPosition(
          index,
          item.values.length,
          padding.left,
          plotWidth,
        );
        final y = padding.top +
            plotHeight -
            (item.values[index] / yMaximum) * plotHeight;
        if (index == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, linePaint);
      for (var index = 0; index < item.values.length; index++) {
        final x = _xPosition(
          index,
          item.values.length,
          padding.left,
          plotWidth,
        );
        final y = padding.top +
            plotHeight -
            (item.values[index] / yMaximum) * plotHeight;
        canvas.drawCircle(Offset(x, y), 3.5, pointPaint);
      }
    }
  }

  double _xPosition(int index, int length, double left, double width) {
    if (length <= 1) return left + width / 2;
    return left + (width / (length - 1)) * index;
  }

  String _compact(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required TextAlign alignment,
    bool anchorRight = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
      ),
      textAlign: alignment,
      textDirection: TextDirection.ltr,
    )..layout();
    final dx =
        anchorRight ? offset.dx - painter.width : offset.dx - painter.width / 2;
    painter.paint(canvas, Offset(dx, offset.dy - painter.height / 2));
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const dashWidth = 4.0;
    const gapWidth = 4.0;
    var x = start.dx;
    while (x < end.dx) {
      canvas.drawLine(
        Offset(x, start.dy),
        Offset((x + dashWidth).clamp(start.dx, end.dx), end.dy),
        paint,
      );
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant _WasteLineChartPainter oldDelegate) => true;
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
