# Smart Recycle Manager — Flutter

แอปสำหรับผู้เก็บขยะของแต่ละหน่วยงาน เชื่อมต่อกับ Django API และฐานข้อมูลจริง
ใช้ดูเครื่องคัดแยก ระดับขยะ ประวัติ การแจ้งเตือน รายงาน และพิมพ์ลาเบล

แอปไม่ใช้ Dummy Data ในการทำงานปกติ ไฟล์ `lib/data/dummy_data.dart` เหลือไว้เพื่ออ้างอิง
จากโค้ดรุ่นเดิมเท่านั้น

## ความสามารถหลัก

- ผู้ใช้เห็นเครื่องทั้งหมดในหน่วยงานของตน
- แผนที่เครื่องคัดแยกจากพิกัดที่ผู้ดูแลกำหนด
- ระดับและน้ำหนักขยะพลาสติก แก้ว และกระป๋องจาก API
- เปิด/ปิดเครื่องพร้อมสถานะกำลังดำเนินการ
- บันทึกการเก็บขยะและไปหน้าพิมพ์ลาเบลโดยอัตโนมัติ
- เลือกพิมพ์ลาเบลผ่านเครื่องพิมพ์หรือบันทึกเป็น PDF
- ประวัติการเก็บขยะ รายงาน กราฟ และส่งออกรายงาน PDF
- รายงานปัญหาเครื่อง
- Push Notification ผ่าน Firebase แม้ปิดแอป
- ตอบรับแจ้งเตือนถังเต็ม และแจ้งชื่อผู้ตอบรับให้สมาชิกหน่วยงาน
- Cache ข้อมูลและรีเฟรชเบื้องหลังเพื่อลดการเรียก API
- เก็บ session ใน Secure Storage ปิดแอปแล้วไม่ต้องเข้าสู่ระบบใหม่จนกว่าจะออกจากระบบ
- แสดงผลภาษาไทยและวันที่ `dd/mm/yyyy`

## โครงสร้างสำคัญ

```text
recycleuser/
├── android/                       Android project และ Firebase config
├── assets/
│   ├── fonts/                     ฟอนต์สำหรับรายงาน PDF
│   └── images/logo.png            โลโก้ระบบ
├── lib/
│   ├── main.dart                  เริ่มแอปและกู้ session
│   ├── models/                    โมเดลข้อมูลจาก API
│   ├── pages/                     หน้าจอทั้งหมด
│   ├── services/
│   │   ├── api_service.dart       Django API, token และ cache
│   │   ├── push_notification_service.dart
│   │   ├── pdf_report_service.dart
│   │   └── label_pdf_service.dart
│   └── widgets/                   Skeleton และแผนที่
├── test/                          ชุดทดสอบ
├── DEPENDENCIES.md                รายการโปรแกรมและ packages
└── pubspec.yaml
```

## ติดตั้ง

รายละเอียดโปรแกรมและ package ทั้งหมดดูที่ [DEPENDENCIES.md](DEPENDENCIES.md)

```powershell
cd D:\Project\recycleuser_flutter\recycleuser
flutter doctor
flutter pub get
flutter analyze
flutter test
```

## ตั้งค่า API

ค่าเริ่มต้นใน Release ชี้ไปที่:

```text
https://smart-recycle-admin.onrender.com/api/v1
```

ทดสอบ Android Emulator กับ Django ในเครื่อง:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

ทดสอบมือถือจริง ให้แทน `192.168.1.10` ด้วย IP ของคอมพิวเตอร์ในเครือข่ายเดียวกัน:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1
```

Django ต้องรันด้วย `python manage.py runserver 0.0.0.0:8000` และ Firewall ต้องอนุญาต
การเชื่อมต่อพอร์ต 8000

## Firebase Push Notification

Android ใช้ไฟล์:

```text
android/app/google-services.json
```

ไฟล์ต้องมาจาก Firebase Android App ที่มี package name ตรงกับ
`applicationId` ใน `android/app/build.gradle.kts`

การแจ้งเตือนเมื่อปิดแอปต้องตั้งค่าทั้งสองฝั่ง:

1. Flutter มี `google-services.json` และอนุญาต Notification
2. Django มี Firebase service-account JSON และตัวแปร `FIREBASE_CREDENTIALS`
3. ผู้ใช้เข้าสู่ระบบอย่างน้อยหนึ่งครั้งเพื่อบันทึก FCM token

## แผนที่

แผนที่ใช้ OpenStreetMap และต้องเชื่อมต่ออินเทอร์เน็ต เครื่องจะแสดงบนแผนที่เมื่อ API ส่ง
`latitude` และ `longitude` ที่ถูกต้อง ผู้ดูแลเพิ่มพิกัดได้จากหน้าจัดการเครื่องของ Admin

## Session การเข้าสู่ระบบ

- Access token และข้อมูลผู้ใช้เก็บใน Flutter Secure Storage
- เมื่อปัดปิดหรือปิดแอป ระบบกู้ session ให้อัตโนมัติ
- Session สิ้นสุดเมื่อกดออกจากระบบ บัญชีถูกระงับ เปลี่ยนรหัสผ่าน หรือ token ถูกเพิกถอน
- การล้างข้อมูลแอปหรือถอนการติดตั้งจะลบ session ในอุปกรณ์

## รันและทดสอบ

```powershell
flutter run
flutter analyze
flutter test
```

## สร้าง APK สำหรับติดตั้งจริง

ต้องมี Release Keystore และ `android/key.properties` ก่อน รายละเอียดใน
[DEPENDENCIES.md](DEPENDENCIES.md)

```powershell
flutter build apk --release
```

ไฟล์ที่ได้:

```text
build/app/outputs/flutter-apk/app-release.apk
```

สำหรับ Google Play:

```powershell
flutter build appbundle --release
```

ห้าม Commit `android/key.properties`, Keystore หรือรหัสผ่าน Keystore ลง Git

## เปลี่ยนไอคอนแอป

แก้ `assets/images/logo.png` แล้วรัน:

```powershell
dart run flutter_launcher_icons
```
