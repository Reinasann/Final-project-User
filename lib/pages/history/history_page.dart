import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/date_range_preset.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loading.dart';
import '../label/label_print_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<CollectionHistoryItem>> _historyFuture;
  String _searchQuery = '';
  String? _selectedMachine;
  String _rangePreset = '7d';
  DateTime? _startDate;
  DateTime? _endDate;
  StreamSubscription<ApiResource>? _cacheSubscription;

  @override
  void initState() {
    super.initState();
    _cacheSubscription = ApiService.cacheUpdates
        .where((resource) => resource == ApiResource.collections)
        .listen((_) {
      if (mounted) setState(_reload);
    });
    _reload();
  }

  void _reload({bool forceRefresh = false}) {
    _historyFuture = ApiService.collections(forceRefresh: forceRefresh);
  }

  @override
  void dispose() {
    _cacheSubscription?.cancel();
    super.dispose();
  }

  Color _typeColor(String type) {
    if (type.contains('พลาสติก')) return Colors.orange;
    if (type.contains('แก้ว')) return Colors.blue;
    if (type.contains('กระป๋อง')) return Colors.green;
    return Colors.grey;
  }

  List<CollectionHistoryItem> _filtered(
    List<CollectionHistoryItem> history,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    final selectedRange = _selectedDateRange(history);
    return history.where((item) {
      final matchesSearch = query.isEmpty ||
          item.machineName.toLowerCase().contains(query) ||
          item.type.toLowerCase().contains(query);
      final matchesMachine =
          _selectedMachine == null || item.machineName == _selectedMachine;
      final parsedDate = parseAppDate(item.date);
      final itemDate = parsedDate == null
          ? null
          : DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      final matchesDate = itemDate != null &&
          !itemDate.isBefore(selectedRange.start) &&
          !itemDate.isAfter(selectedRange.end);
      return matchesSearch && matchesMachine && matchesDate;
    }).toList();
  }

  DateTimeRange _selectedDateRange(List<CollectionHistoryItem> history) {
    if (_startDate != null && _endDate != null) {
      return DateTimeRange(start: _startDate!, end: _endDate!);
    }
    final dates = history
        .map((item) => parseAppDate(item.date))
        .whereType<DateTime>()
        .map((date) => DateTime(date.year, date.month, date.day))
        .toList()
      ..sort();
    final now = DateTime.now();
    final end =
        dates.isEmpty ? DateTime(now.year, now.month, now.day) : dates.last;
    return appPresetDateRange(_rangePreset, end);
  }

  Future<void> _pickDateRange(List<CollectionHistoryItem> history) async {
    final initialRange = _selectedDateRange(history);
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          initialRange.end.isAfter(DateTime.now()) ? null : initialRange,
      helpText: 'เลือกช่วงวันที่',
      cancelText: 'ยกเลิก',
      confirmText: 'ตกลง',
    );
    if (range != null) {
      setState(() {
        _rangePreset = 'custom';
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  void _selectPreset(String preset) {
    setState(() {
      _rangePreset = preset;
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการเก็บขยะ'),
        actions: [
          IconButton(
            tooltip: 'โหลดข้อมูลใหม่',
            onPressed: () => setState(() => _reload(forceRefresh: true)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<CollectionHistoryItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppSkeletonLoading(layout: AppSkeletonLayout.list);
          }
          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: () => setState(() => _reload(forceRefresh: true)),
            );
          }

          final history = snapshot.data ?? const [];
          final machines =
              history.map((item) => item.machineName).toSet().toList()..sort();
          final selectedRange = _selectedDateRange(history);
          final filtered = _filtered(history);
          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'ค้นหาชื่อเครื่องหรือประเภทขยะ',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedMachine,
                        decoration: const InputDecoration(
                          labelText: 'เครื่องคัดแยก',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('ทุกเครื่อง'),
                          ),
                          ...machines.map(
                            (name) => DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedMachine = value),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'ช่วงวันที่ ${formatAppDate(selectedRange.start)} - ${formatAppDate(selectedRange.end)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: appDateRangePresets.map((preset) {
                            final selected = _rangePreset == preset.key;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(preset.label),
                                selected: selected,
                                onSelected: (_) => preset.isCustom
                                    ? _pickDateRange(history)
                                    : _selectPreset(preset.key),
                                showCheckmark: false,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('ไม่พบประวัติการเก็บขยะ'))
                    : RefreshIndicator(
                        onRefresh: () async {
                          setState(() => _reload(forceRefresh: true));
                          await _historyFuture;
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final color = _typeColor(item.type);
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: ListTile(
                                title: Text(
                                  item.machineName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '${item.type} • ${item.weight}\n'
                                    '${item.date} เวลา ${item.time} น.',
                                  ),
                                ),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      color.withValues(alpha: 0.15),
                                  child: Icon(Icons.recycling, color: color),
                                ),
                                trailing: IconButton(
                                  tooltip: 'พิมพ์ฉลาก',
                                  icon: const Icon(Icons.print),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LabelPrintPage(
                                        machineName: item.machineName,
                                        preSelectedType: item.type,
                                        weightKg: double.tryParse(
                                          item.weight.split(' ').first,
                                        ),
                                        collectedAt: parseAppDate(item.date),
                                        batchCode: 'COL-${item.id}',
                                      ),
                                    ),
                                  ),
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('โหลดข้อมูลไม่สำเร็จ\n$message', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }
}
