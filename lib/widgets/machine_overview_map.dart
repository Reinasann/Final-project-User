import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/models.dart';

class MachineOverviewMap extends StatelessWidget {
  const MachineOverviewMap({
    super.key,
    required this.machines,
    required this.onMachineTap,
  });

  final List<Machine> machines;
  final ValueChanged<Machine> onMachineTap;

  @override
  Widget build(BuildContext context) {
    final locatedMachines = machines.where((item) => item.hasCoordinates).toList();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, color: Colors.teal),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'แผนที่เครื่องคัดแยก',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(
                  'มีพิกัด ${locatedMachines.length}/${machines.length} เครื่อง',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          if (locatedMachines.isEmpty)
            Container(
              height: 140,
              width: double.infinity,
              color: Colors.grey.shade100,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off_outlined, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'ยังไม่มีเครื่องที่กำหนดพิกัด\nเพิ่มพิกัดได้จากหน้าจัดการเครื่องของผู้ดูแลระบบ',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 230,
              child: FlutterMap(
                key: ValueKey(
                  locatedMachines
                      .map((item) =>
                          '${item.id}:${item.latitude}:${item.longitude}:${item.isOn}')
                      .join('|'),
                ),
                options: MapOptions(
                  initialCenter: LatLng(
                    locatedMachines.first.latitude!,
                    locatedMachines.first.longitude!,
                  ),
                  initialCameraFit: CameraFit.coordinates(
                    coordinates: locatedMachines
                        .map((item) => LatLng(item.latitude!, item.longitude!))
                        .toList(),
                    padding: const EdgeInsets.all(52),
                    maxZoom: 16,
                  ),
                  minZoom: 3,
                  maxZoom: 19,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.recycle_admin',
                    maxZoom: 19,
                  ),
                  MarkerLayer(
                    markers: locatedMachines.map((machine) {
                      return Marker(
                        point: LatLng(machine.latitude!, machine.longitude!),
                        width: 52,
                        height: 52,
                        child: Tooltip(
                          message: '${machine.name}\n${machine.location}',
                          child: Semantics(
                            button: true,
                            label: 'ดูรายละเอียด ${machine.name}',
                            child: InkWell(
                              onTap: () => onMachineTap(machine),
                              customBorder: const CircleBorder(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: machine.isOn ? Colors.teal : Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.recycling,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 9, color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                _legendDot(Colors.teal, 'ออนไลน์'),
                const SizedBox(width: 16),
                _legendDot(Colors.red, 'ออฟไลน์'),
                const Spacer(),
                const Text(
                  'แตะหมุดเพื่อดูรายละเอียด',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
