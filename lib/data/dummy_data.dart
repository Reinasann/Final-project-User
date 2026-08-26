import '../models/models.dart';

List<Machine> mockMachines = [
  Machine(
    id: 'M001',
    name: 'Recycle Station A',
    location: 'โรงอาหารกลาง (Zone 1)',
    isOn: true,
    plasticLevel: 0.4,
    glassLevel: 0.95, // เต็ม
    canLevel: 0.2,
  ),
  Machine(
    id: 'M002',
    name: 'Recycle Station B',
    location: 'หอพักนักศึกษาชาย',
    isOn: false,
    plasticLevel: 0.1,
    glassLevel: 0.1,
    canLevel: 0.0,
  ),
  Machine(
    id: 'M003',
    name: 'Recycle Station C',
    location: 'อาคารเรียนรวม 5',
    isOn: true,
    plasticLevel: 0.8,
    glassLevel: 0.2,
    canLevel: 0.5,
  ),
  Machine(
    id: 'M004',
    name: 'Recycle Station D',
    location: 'ศูนย์กีฬา',
    isOn: true,
    plasticLevel: 0.25,
    glassLevel: 0.15,
    canLevel: 0.10,
  ),
];

List<NotificationItem> mockNotifications = [
  NotificationItem(
    id: 'N001',
    title: 'ถังเต็ม (วิกฤต)',
    message: 'ถังแก้วที่เครื่อง Station A เต็มแล้ว (95%)',
    time: '10 นาทีที่แล้ว',
    machineId: 'M001',
  ),
  NotificationItem(
    id: 'N002',
    title: 'ระบบปิดการทำงาน',
    message: 'เครื่อง Station B ถูกปิดระบบ',
    time: '1 ชั่วโมงที่แล้ว',
    machineId: 'M002',
  ),
  NotificationItem(
    id: 'N003',
    title: 'ถังเต็ม',
    message: 'ถังพลาสติกที่เครื่อง Station C เต็มแล้ว',
    time: '2 นาทีที่แล้ว',
    machineId: 'M003',
  ),
];

// ข้อมูลจำลองประวัติการเก็บขยะ (เพิ่มเติม)
List<CollectionHistoryItem> mockCollectionHistory = [
  CollectionHistoryItem(
    id: 'H001',
    date: '10/02/2024',
    time: '10:30',
    machineId: 'M001',
    machineName: 'Recycle Station A',
    type: 'พลาสติก',
    weight: '3.2 kg',
  ),
  CollectionHistoryItem(
    id: 'H002',
    date: '10/02/2024',
    time: '11:15',
    machineId: 'M001',
    machineName: 'Recycle Station A',
    type: 'แก้ว',
    weight: '5.0 kg',
  ),
  CollectionHistoryItem(
    id: 'H003',
    date: '09/02/2024',
    time: '09:00',
    machineId: 'M002',
    machineName: 'Recycle Station B',
    type: 'กระป๋อง',
    weight: '2.1 kg',
  ),
  CollectionHistoryItem(
    id: 'H004',
    date: '08/02/2024',
    time: '14:20',
    machineId: 'M001',
    machineName: 'Recycle Station A',
    type: 'พลาสติก',
    weight: '4.5 kg',
  ),
  CollectionHistoryItem(
    id: 'H005',
    date: '08/02/2024',
    time: '15:00',
    machineId: 'M002',
    machineName: 'Recycle Station B',
    type: 'แก้ว',
    weight: '3.8 kg',
  ),
];

// ข้อมูลจำลองรายงานปัญหา (เพิ่มเติม)
List<IssueReportItem> mockIssueReports = [
  IssueReportItem(
    id: 'R001',
    machineId: 'M001',
    title: 'เซ็นเซอร์ขัดข้อง',
    description: 'เซ็นเซอร์ช่องพลาสติกไม่ทำงาน ไฟไม่ติด',
    date: '01/02/2024',
    status: 'Resolved',
  ),
  IssueReportItem(
    id: 'R002',
    machineId: 'M001',
    title: 'ฝาถังปิดไม่สนิท',
    description: 'ฝาถังช่องแก้วปิดไม่สนิท ทำให้มีกลิ่น',
    date: '05/02/2024',
    status: 'Pending',
  ),
  IssueReportItem(
    id: 'R003',
    machineId: 'M002',
    title: 'เครื่องดับเอง',
    description: 'เครื่องดับเองบ่อยครั้งช่วงบ่าย',
    date: '08/02/2024',
    status: 'Pending',
  ),
];

Machine? findMachineById(String machineId) {
  for (final machine in mockMachines) {
    if (machine.id == machineId) return machine;
  }
  return null;
}
