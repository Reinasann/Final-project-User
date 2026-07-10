import 'package:flutter/material.dart';
import '../../data/dummy_data.dart';
import '../machine/machine_detail_page.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final myNotifications = mockNotifications.where((n) {
      final machine = mockMachines.firstWhere((m) => m.id == n.machineId);
      return machine.caretakerId == currentUser.id;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        actions: [
          TextButton(onPressed: () {}, child: const Text('อ่านทั้งหมด')),
        ],
      ),
      body: myNotifications.isEmpty
          ? const Center(child: Text('ไม่มีการแจ้งเตือนใหม่'))
          : ListView.separated(
              itemCount: myNotifications.length,
              separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notif = myNotifications[index];
                final machineName = mockMachines
                    .firstWhere((m) => m.id == notif.machineId)
                    .name;
                return Container(
                  color: notif.isRead
                      ? Colors.white
                      : Colors.blue.withOpacity(0.05),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade100,
                      child: const Icon(
                        Icons.notifications_active,
                        color: Colors.red,
                      ),
                    ),
                    title: Text(
                      notif.title,
                      style: TextStyle(
                        fontWeight: notif.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notif.message),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.smart_toy,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$machineName • ${notif.time}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () {
                      final machine = mockMachines.firstWhere(
                        (m) => m.id == notif.machineId,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MachineDetailPage(machine: machine),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

