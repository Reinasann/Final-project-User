import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import 'machine/machine_list_page.dart';
import 'history/history_page.dart';
import 'notification/notification_page.dart';
import 'stats/stats_page.dart';
import 'profile/profile_page.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;
  const MainLayout({super.key, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  // คำนวณจำนวนแจ้งเตือนของผู้ใช้
  int get notificationCount => mockNotifications
      .where(
        (n) =>
            mockMachines.firstWhere((m) => m.id == n.machineId).caretakerId ==
            currentUser.id,
      )
      .length;

  final List<Widget> _pages = [
    const MachineListPage(),
    const HistoryPage(),
    const NotificationPage(), // เพิ่มหน้าประวัติ
    const StatsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.grid_view),
            label: 'เครื่องคัดแยก',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history),
            label: 'ประวัติ',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$notificationCount'),
              isLabelVisible: notificationCount > 0,
              child: const Icon(Icons.notifications),
            ),
            label: 'แจ้งเตือน',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'สถิติ',
          ),
          const NavigationDestination(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}

