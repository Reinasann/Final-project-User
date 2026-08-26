String formatAppDate(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}

DateTime? parseAppDate(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  final displayParts = text.split('/');
  if (displayParts.length == 3) {
    final day = int.tryParse(displayParts[0]);
    final month = int.tryParse(displayParts[1]);
    final year = int.tryParse(displayParts[2]);
    if (day != null && month != null && year != null) {
      return DateTime(year, month, day);
    }
  }
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return null;
  final local = parsed.toLocal();
  return DateTime(local.year, local.month, local.day);
}

class User {
  String id;
  String name;
  String role;
  String email;
  String phone;
  String startDate;
  String organizationName;

  User({
    required this.id,
    required this.name,
    required this.role,
    this.email = 'staff@recycle.com',
    this.phone = '081-234-5678',
    this.startDate = '01/01/2023',
    this.organizationName = '',
  });
}

class Machine {
  final String id;
  final String name;
  final String location;
  bool isOn;
  double plasticLevel;
  double glassLevel;
  double canLevel;
  double plasticWeight;
  double glassWeight;
  double canWeight;

  Machine({
    required this.id,
    required this.name,
    required this.location,
    this.isOn = true,
    this.plasticLevel = 0.0,
    this.glassLevel = 0.0,
    this.canLevel = 0.0,
    this.plasticWeight = 0.0,
    this.glassWeight = 0.0,
    this.canWeight = 0.0,
  });

  factory Machine.fromApi(Map<String, dynamic> json) {
    final bins = <String, Map<String, dynamic>>{};
    for (final item in (json['bins'] as List<dynamic>? ?? const [])) {
      if (item is Map<String, dynamic>) {
        bins[item['waste_type'] as String] = item;
      }
    }
    double level(String type) =>
        (double.tryParse('${bins[type]?['level_percent']}') ?? 0) / 100;
    double weight(String type) =>
        double.tryParse('${bins[type]?['weight_kg']}') ?? 0;
    return Machine(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String? ?? '',
      isOn: json['status'] == 'Online',
      plasticLevel: level('plastic'),
      glassLevel: level('glass'),
      canLevel: level('can'),
      plasticWeight: weight('plastic'),
      glassWeight: weight('glass'),
      canWeight: weight('can'),
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final String machineId;
  final bool isRead;
  final bool requiresAcknowledgement;
  final String acknowledgedByName;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.machineId,
    this.isRead = false,
    this.requiresAcknowledgement = false,
    this.acknowledgedByName = '',
  });

  factory NotificationItem.fromApi(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse('${json['created_at']}')?.toLocal();
    final time = createdAt == null
        ? ''
        : '${createdAt.day.toString().padLeft(2, '0')}/'
            '${createdAt.month.toString().padLeft(2, '0')}/'
            '${createdAt.year} '
            '${createdAt.hour.toString().padLeft(2, '0')}:'
            '${createdAt.minute.toString().padLeft(2, '0')}';
    return NotificationItem(
      id: '${json['id']}',
      title: '${json['title'] ?? ''}',
      message: '${json['message'] ?? ''}',
      time: time,
      machineId: '${json['machine_id'] ?? ''}',
      isRead: json['is_read'] == true,
      requiresAcknowledgement: json['requires_acknowledgement'] == true,
      acknowledgedByName: '${json['acknowledged_by_name'] ?? ''}',
    );
  }
}

// Model สำหรับประวัติการเก็บขยะ
class CollectionHistoryItem {
  final String id;
  final String date; // DD/MM/YYYY for display
  final String time;
  final String machineId;
  final String machineName;
  final String type;
  final String weight;

  CollectionHistoryItem({
    required this.id,
    required this.date,
    required this.time,
    required this.machineId,
    required this.machineName,
    required this.type,
    required this.weight,
  });

  factory CollectionHistoryItem.fromApi(Map<String, dynamic> json) {
    final collectedAt = DateTime.tryParse('${json['collected_at']}')?.toLocal();
    final date = formatAppDate(collectedAt);
    final time = collectedAt == null
        ? ''
        : '${collectedAt.hour.toString().padLeft(2, '0')}:'
            '${collectedAt.minute.toString().padLeft(2, '0')}';
    final wasteType = {
          'plastic': 'พลาสติก',
          'glass': 'แก้ว',
          'can': 'กระป๋อง',
        }['${json['waste_type']}'] ??
        '${json['waste_type'] ?? ''}';
    return CollectionHistoryItem(
      id: '${json['id']}',
      date: date,
      time: time,
      machineId: '${json['machine_id']}',
      machineName: '${json['machine_name'] ?? ''}',
      type: wasteType,
      weight: '${json['weight_kg'] ?? 0} กก.',
    );
  }
}

// Model สำหรับรายการแจ้งปัญหา
class IssueReportItem {
  final String id;
  final String machineId;
  final String machineName;
  final String title;
  final String description;
  final String date;
  final String status; // Pending, Resolved

  IssueReportItem({
    required this.id,
    required this.machineId,
    this.machineName = '',
    required this.title,
    required this.description,
    required this.date,
    required this.status,
  });

  factory IssueReportItem.fromApi(Map<String, dynamic> json) {
    final reportedAt = DateTime.tryParse('${json['reported_at']}')?.toLocal();
    final date = formatAppDate(reportedAt);
    return IssueReportItem(
      id: '${json['id']}',
      machineId: '${json['machine_id']}',
      machineName: '${json['machine_name'] ?? json['machine_id'] ?? ''}',
      title: '${json['category'] ?? ''}',
      description: '${json['description'] ?? ''}',
      date: date,
      status: '${json['status'] ?? ''}',
    );
  }
}
