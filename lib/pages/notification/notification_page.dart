import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/skeleton_loading.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late Future<List<NotificationItem>> _future;
  final Set<String> _acknowledgingIds = {};
  StreamSubscription<ApiResource>? _cacheSubscription;

  @override
  void initState() {
    super.initState();
    _cacheSubscription = ApiService.cacheUpdates
        .where((resource) => resource == ApiResource.notifications)
        .listen((_) {
      if (mounted) setState(_reload);
    });
    _reload();
  }

  void _reload({bool forceRefresh = false}) {
    _future = ApiService.notifications(forceRefresh: forceRefresh);
  }

  @override
  void dispose() {
    _cacheSubscription?.cancel();
    super.dispose();
  }

  Future<void> _markRead(NotificationItem item) async {
    if (item.isRead) return;
    try {
      await ApiService.markNotificationRead(item.id);
      if (mounted) setState(_reload);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปเดตการแจ้งเตือนไม่สำเร็จ: $error')),
      );
    }
  }

  Future<void> _markAllRead(List<NotificationItem> items) async {
    try {
      await Future.wait(
        items.where((item) => !item.isRead).map(
              (item) => ApiService.markNotificationRead(item.id),
            ),
      );
      if (mounted) setState(_reload);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปเดตการแจ้งเตือนไม่สำเร็จ: $error')),
      );
    }
  }

  Future<void> _acknowledge(NotificationItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันการตอบรับ'),
        content: Text(
          'คุณต้องการตอบรับการดำเนินการสำหรับ “${item.title}” ใช่หรือไม่',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ตอบรับ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _acknowledgingIds.add(item.id));
    try {
      final result = await ApiService.acknowledgeNotification(item.id);
      if (!mounted) return;
      final alreadyAcknowledged = result['already_acknowledged'] == true;
      final acknowledgedBy = '${result['acknowledged_by_name'] ?? ''}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            alreadyAcknowledged
                ? '$acknowledgedBy ตอบรับการแจ้งเตือนนี้แล้ว'
                : 'ตอบรับแล้ว ระบบแจ้งผู้ใช้อื่นในหน่วยงานเรียบร้อย',
          ),
        ),
      );
      setState(() => _reload(forceRefresh: true));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ตอบรับการแจ้งเตือนไม่สำเร็จ: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _acknowledgingIds.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        actions: [
          FutureBuilder<List<NotificationItem>>(
            future: _future,
            builder: (context, snapshot) => TextButton(
              onPressed:
                  snapshot.hasData ? () => _markAllRead(snapshot.data!) : null,
              child: const Text('อ่านทั้งหมด'),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<NotificationItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppSkeletonLoading(layout: AppSkeletonLayout.list);
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton.icon(
                onPressed: () => setState(() => _reload(forceRefresh: true)),
                icon: const Icon(Icons.refresh),
                label: Text('โหลดไม่สำเร็จ: ${snapshot.error}\nลองอีกครั้ง'),
              ),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('ไม่มีการแจ้งเตือน'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _reload(forceRefresh: true));
              await _future;
            },
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                final acknowledging = _acknowledgingIds.contains(item.id);
                return ColoredBox(
                  color: item.isRead
                      ? Colors.transparent
                      : Colors.blue.withValues(alpha: 0.06),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: item.requiresAcknowledgement
                          ? Colors.orange.shade100
                          : Colors.blue.shade100,
                      child: Icon(
                        item.requiresAcknowledgement
                            ? Icons.notification_important
                            : Icons.notifications_active,
                        color: item.requiresAcknowledgement
                            ? Colors.orange.shade800
                            : Colors.blue.shade700,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight:
                            item.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.message),
                        const SizedBox(height: 4),
                        Text(
                          item.time,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (item.requiresAcknowledgement) ...[
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed:
                                acknowledging ? null : () => _acknowledge(item),
                            icon: acknowledging
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.task_alt),
                            label: Text(
                              acknowledging ? 'กำลังตอบรับ…' : 'ตอบรับ',
                            ),
                          ),
                        ] else if (item.acknowledgedByName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'ตอบรับโดย ${item.acknowledgedByName}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: item.isRead
                        ? const Icon(Icons.done, color: Colors.green)
                        : const Icon(Icons.circle,
                            size: 10, color: Colors.blue),
                    onTap: () => _markRead(item),
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
