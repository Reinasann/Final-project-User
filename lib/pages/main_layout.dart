import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/push_notification_service.dart';
import '../services/session_service.dart';
import 'auth/login_page.dart';
import 'machine/machine_list_page.dart';
import 'history/history_page.dart';
import 'notification/notification_page.dart';
import 'report/report_page.dart';
import 'profile/profile_page.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;
  const MainLayout({super.key, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with WidgetsBindingObserver {
  late int _currentIndex;
  late final List<Widget?> _pages;
  int _notificationCount = 0;
  Timer? _refreshTimer;
  StreamSubscription<ApiResource>? _notificationSubscription;
  StreamSubscription<void>? _notificationOpenSubscription;
  StreamSubscription<void>? _sessionExpiredSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex.clamp(0, 4);
    _pages = List<Widget?>.filled(5, null);
    if (PushNotificationService.consumePendingNotificationOpen()) {
      _currentIndex = 2;
    }
    _pages[_currentIndex] = _createPage(_currentIndex);
    _notificationSubscription = ApiService.cacheUpdates
        .where((resource) => resource == ApiResource.notifications)
        .listen((_) => _loadNotificationCount());
    _notificationOpenSubscription =
        PushNotificationService.notificationOpenRequests.listen((_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = 2;
        _pages[2] ??= _createPage(2);
      });
      _loadNotificationCount(forceRefresh: true);
    });
    _sessionExpiredSubscription = ApiService.sessionExpired.listen((_) {
      if (!mounted) return;
      clearCurrentUser();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    });
    _loadNotificationCount();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(ApiService.refreshStaleCaches()),
    );
  }

  Future<void> _loadNotificationCount({bool forceRefresh = false}) async {
    try {
      final items = await ApiService.notifications(
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _notificationCount = items.where((item) => !item.isRead).length;
        });
      }
    } catch (_) {
      // หน้าการแจ้งเตือนจะแสดงข้อผิดพลาดพร้อมปุ่มลองใหม่โดยละเอียด
    }
  }

  Widget _createPage(int index) => switch (index) {
        0 => const MachineListPage(),
        1 => const HistoryPage(),
        2 => const NotificationPage(),
        3 => const ReportPage(),
        4 => const ProfilePage(),
        _ => const SizedBox.shrink(),
      };

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ApiService.refreshStaleCaches());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _notificationSubscription?.cancel();
    _notificationOpenSubscription?.cancel();
    _sessionExpiredSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (final page in _pages) page ?? const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _currentIndex = idx;
            _pages[idx] ??= _createPage(idx);
          });
          if (idx == 2) _loadNotificationCount();
        },
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
              label: Text('$_notificationCount'),
              isLabelVisible: _notificationCount > 0,
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
}
