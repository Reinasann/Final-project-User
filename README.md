# RecycleAdmin (Smart Recycle Manager) — Flutter Project

โปรเจกต์นี้แปลงมาจากไฟล์ `main.dart` เป็นโครงสร้าง Flutter project
มาตรฐาน โดยแยก data models, dummy data, และแต่ละหน้าจอออกเป็นไฟล์ของตัวเอง เพื่อให้ดูแลและ
ต่อยอดได้ง่ายขึ้น

## โครงสร้างโปรเจกต์

```
lib/
├── main.dart                          # entry point + RecycleApp (MaterialApp)
├── models/
│   └── models.dart                    # User, Machine, NotificationItem,
│                                       # CollectionHistoryItem, IssueReportItem
├── data/
│   └── dummy_data.dart                # currentUser, mockMachines, mockNotifications,
│                                       # mockCollectionHistory, mockIssueReports
└── pages/
    ├── main_layout.dart               # bottom-nav shell (Machines/History/Alerts/Stats/Profile)
    ├── auth/
    │   ├── login_page.dart
    │   ├── register_page.dart
    │   └── forgot_password_page.dart
    ├── machine/
    │   ├── machine_list_page.dart
    │   └── machine_detail_page.dart
    ├── history/
    │   └── history_page.dart
    ├── notification/
    │   └── notification_page.dart
    ├── stats/
    │   └── stats_page.dart
    ├── profile/
    │   ├── profile_page.dart
    │   ├── edit_profile_page.dart
    │   └── change_password_page.dart
    ├── report/
    │   └── report_issue_page.dart
    └── label/
        └── label_print_page.dart
```

## ข้อมูลจำลอง (Dummy Data)

ข้อมูลตัวอย่างทั้งหมดอยู่ใน `lib/data/dummy_data.dart` ประกอบด้วย:

- `currentUser` — ผู้ใช้งานปัจจุบัน (staff)
- `mockMachines` — เครื่อง Recycle Station 4 เครื่อง (A–D)
- `mockNotifications` — การแจ้งเตือน 3 รายการ
- `mockCollectionHistory` — ประวัติการเก็บขยะ 5 รายการ
- `mockIssueReports` — รายงานปัญหา 3 รายการ

แก้ไข/เพิ่มข้อมูลจำลองได้โดยตรงที่ไฟล์นี้ไฟล์เดียว ไม่ต้องไปไล่หาในไฟล์หน้าจอต่างๆ

## วิธีรันโปรเจกต์

โปรเจกต์นี้มีเฉพาะโค้ด Dart/Flutter (`lib/`, `pubspec.yaml`) ยังไม่ได้สร้างโฟลเดอร์ platform
(`android/`, `ios/`, `web/` ฯลฯ) เนื่องจากต้องสร้างผ่านเครื่องมือ Flutter SDK บนเครื่องของคุณเอง

1. ติดตั้ง [Flutter SDK](https://docs.flutter.dev/get-started/install) ให้เรียบร้อย
2. คัดลอกโฟลเดอร์นี้ไปยังเครื่อง แล้วรันคำสั่งต่อไปนี้ในโฟลเดอร์โปรเจกต์:

```bash
flutter create .        # เติม android/ios/web/ ให้ครบ (จะไม่ทับ lib/ หรือ pubspec.yaml ที่มีอยู่)
flutter pub get
flutter run
```

## หมายเหตุ

- โค้ดทั้งหมดคือของเดิมจาก `main.dart` เพียงแค่ถูกแยกไฟล์และเพิ่ม `import` ให้ครบ ไม่มีการ
  เปลี่ยนแปลง logic หรือ UI ใดๆ
- ตรวจสอบวงเล็บปีกกาทุกไฟล์แล้วว่าสมดุลครบถ้วน แต่ยังไม่ได้รันผ่าน Flutter/Dart analyzer จริง
  (เครื่องมือในระบบนี้ไม่มี Flutter SDK) แนะนำให้รัน `flutter analyze` อีกครั้งหลังดาวน์โหลดไปใช้งาน
