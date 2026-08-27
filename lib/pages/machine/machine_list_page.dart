import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'machine_detail_page.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loading.dart';
import '../../widgets/machine_overview_map.dart';

class MachineListPage extends StatefulWidget {
  const MachineListPage({super.key});

  @override
  State<MachineListPage> createState() => _MachineListPageState();
}

class _MachineListPageState extends State<MachineListPage> {
  String _searchQuery = '';
  // Requirement 3: ตัด Filter เลือกเครื่องออก บังคับให้แสดงเฉพาะเครื่องที่ดูแล
  // bool _showMyMachinesOnly = true;
  String _statusFilter = 'All';
  List<Machine> _machines = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<ApiResource>? _cacheSubscription;

  @override
  void initState() {
    super.initState();
    _cacheSubscription = ApiService.cacheUpdates
        .where((resource) => resource == ApiResource.machines)
        .listen((_) => _loadMachines(silent: true));
    _loadMachines();
  }

  Future<void> _loadMachines({
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    setState(() {
      _loading = _machines.isEmpty && !silent;
      if (!silent) _error = null;
    });
    try {
      final machines = await ApiService.machines(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _machines = machines;
          _error = null;
        });
      }
    } catch (error) {
      if (_machines.isEmpty) _error = error.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _cacheSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Machine> filteredMachines = _machines.where((m) {
      // Requirement 3: กรองแสดงเฉพาะเครื่องของผู้ดูแลคนนั้นๆ เสมอ
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!m.name.toLowerCase().contains(query) &&
            !m.location.toLowerCase().contains(query)) {
          return false;
        }
      }
      if (_statusFilter != 'All') {
        if (_statusFilter == 'Online' && !m.isOn) return false;
        if (_statusFilter == 'Offline' && m.isOn) return false;
        if (_statusFilter == 'Full') {
          bool isFull =
              m.plasticLevel >= 0.9 || m.glassLevel >= 0.9 || m.canLevel >= 0.9;
          if (!isFull) return false;
        }
      }
      return true;
    }).toList();

    Future<void> openMachine(Machine machine) async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MachineDetailPage(machine: machine),
        ),
      );
      if (mounted) _loadMachines();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการเครื่องรีไซเคิล'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อเครื่อง หรือ สถานที่...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Column(
              children: [
                // Requirement 3: นำแถบเลือกเครื่องที่ดูแล/ทั้งหมดออก
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('ทั้งหมด', 'All'),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'ออนไลน์',
                        'Online',
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip('ออฟไลน์', 'Offline', color: Colors.red),
                      const SizedBox(width: 8),
                      _buildFilterChip('ถังเต็ม', 'Full', color: Colors.orange),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const AppSkeletonLoading(layout: AppSkeletonLayout.cards)
                : _error != null
                    ? Center(
                        child: ElevatedButton(
                            onPressed: () => _loadMachines(forceRefresh: true),
                            child: const Text('ลองใหม่')))
                    : filteredMachines.isEmpty
                        ? const Center(
                            child: Text(
                              'ไม่พบข้อมูลเครื่อง',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: filteredMachines.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return MachineOverviewMap(
                                  machines: filteredMachines,
                                  onMachineTap: openMachine,
                                );
                              }

                              final machine = filteredMachines[index - 1];

                              return Card(
                                elevation: 2,
                                margin: EdgeInsets.fromLTRB(
                                  16,
                                  index == 1 ? 16 : 0,
                                  16,
                                  16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => openMachine(machine),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: machine.isOn
                                                ? Colors.green.shade50
                                                : Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.smart_toy,
                                            color: machine.isOn
                                                ? Colors.green
                                                : Colors.grey,
                                            size: 30,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                machine.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_on,
                                                    size: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      machine.location,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: machine.isOn
                                                          ? Colors.green
                                                              .withValues(
                                                              alpha: 0.1,
                                                            )
                                                          : Colors.red
                                                              .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      machine.isOn
                                                          ? 'ออนไลน์'
                                                          : 'ออฟไลน์',
                                                      style: TextStyle(
                                                        color: machine.isOn
                                                            ? Colors.green
                                                            : Colors.red,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  if (machine.plasticLevel >=
                                                          0.9 ||
                                                      machine.glassLevel >=
                                                          0.9 ||
                                                      machine.canLevel >= 0.9)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                        left: 8.0,
                                                      ),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.orange
                                                              .withValues(
                                                                  alpha: 0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                        child: const Text(
                                                          'เต็ม!',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.orange,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
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

  Widget _buildFilterChip(
    String label,
    String value, {
    Color color = Colors.grey,
  }) {
    bool isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) =>
          setState(() => _statusFilter = selected ? value : 'All'),
      selectedColor: color == Colors.grey
          ? Colors.teal.shade100
          : color.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected
            ? (color == Colors.grey ? Colors.teal[800] : color)
            : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
    );
  }
}
