class User {
  String id;
  String name;
  String role;
  String email;
  String phone;
  String startDate;

  User({
    required this.id,
    required this.name,
    required this.role,
    this.email = 'staff@recycle.com',
    this.phone = '081-234-5678',
    this.startDate = '01/01/2023',
  });
}

class Machine {
  final String id;
  final String name;
  final String location;
  final String caretakerId;
  bool isOn;
  double plasticLevel;
  double glassLevel;
  double canLevel;

  Machine({
    required this.id,
    required this.name,
    required this.location,
    required this.caretakerId,
    this.isOn = true,
    this.plasticLevel = 0.0,
    this.glassLevel = 0.0,
    this.canLevel = 0.0,
  });
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final String machineId;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.machineId,
    this.isRead = false,
  });
}

// Model สำหรับประวัติการเก็บขยะ
class CollectionHistoryItem {
  final String id;
  final String date; // YYYY-MM-DD for sorting/filtering
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
}

// Model สำหรับรายการแจ้งปัญหา
class IssueReportItem {
  final String id;
  final String machineId;
  final String title;
  final String description;
  final String date;
  final String status; // Pending, Resolved

  IssueReportItem({
    required this.id,
    required this.machineId,
    required this.title,
    required this.description,
    required this.date,
    required this.status,
  });
}

