# โปรแกรมและส่วนเสริมที่ต้องติดตั้ง — Flutter

เวอร์ชัน package ที่โปรเจกต์ใช้งานจริงกำหนดใน `pubspec.yaml` และล็อกไว้ใน
`pubspec.lock`

## โปรแกรมหลัก

| โปรแกรม | จำเป็นเมื่อ | หมายเหตุ |
| --- | --- | --- |
| Flutter SDK | พัฒนา ทดสอบ และ Build | โปรเจกต์ใช้ Dart `>=3.0.0 <4.0.0` |
| Android Studio | Build และทดสอบ Android | ติดตั้ง Android SDK, Platform Tools และ Emulator |
| JDK | Build Android | ใช้ JDK ที่ Android Studio/Flutter แนะนำ |
| Chrome | ทดสอบ Flutter Web | ไม่จำเป็นสำหรับ APK |
| Git | จัดการ source code | ไม่จำเป็นสำหรับการรัน APK ที่ build แล้ว |

ตรวจสอบเครื่อง:

```powershell
flutter doctor -v
flutter devices
```

## Flutter packages

ติดตั้งทั้งหมดด้วย:

```powershell
flutter pub get
```

### Packages ที่ใช้ตอนรันแอป

| Package | เวอร์ชัน | หน้าที่ |
| --- | --- | --- |
| `flutter_localizations` | Flutter SDK | ภาษาไทย ปฏิทินและ widget localization |
| `cupertino_icons` | `^1.0.6` | ชุดไอคอน Cupertino |
| `http` | `^1.2.2` | ติดต่อ Django REST API |
| `intl` | `^0.20.2` | จัดรูปแบบวันที่และข้อความ |
| `flutter_secure_storage` | `^10.3.1` | เก็บ Bearer token แบบเข้ารหัส |
| `firebase_core` | `^4.13.0` | เริ่มต้น Firebase |
| `firebase_messaging` | `^16.5.0` | รับ Firebase Cloud Messaging |
| `flutter_local_notifications` | `^20.1.0` | แสดง Notification ภายในอุปกรณ์ |
| `flutter_map` | `^8.3.1` | แสดงแผนที่ OpenStreetMap |
| `latlong2` | `^0.10.1` | จัดการพิกัดละติจูดและลองจิจูด |
| `pdf` | `^3.12.0` | สร้างรายงานและลาเบล PDF |
| `printing` | `^5.14.3` | เลือกเครื่องพิมพ์ แสดงตัวอย่าง และแชร์ PDF |

### Packages สำหรับพัฒนา

| Package | เวอร์ชัน | หน้าที่ |
| --- | --- | --- |
| `flutter_test` | Flutter SDK | Widget และ unit tests |
| `flutter_lints` | `^3.0.0` | กฎตรวจคุณภาพโค้ด |
| `flutter_launcher_icons` | `^0.14.4` | สร้างไอคอน Android, iOS, Web และ Desktop |

## ไฟล์ตั้งค่าที่ต้องมี

### Firebase Android

```text
android/app/google-services.json
```

หากเปลี่ยน package name ต้องสร้าง Firebase Android App ใหม่ให้ตรงกันและดาวน์โหลดไฟล์ใหม่

### Release Keystore

สร้างเพียงครั้งเดียวและสำรองอย่างปลอดภัย:

```powershell
keytool -genkeypair -v `
  -keystore smart-recycle-release.jks `
  -keyalg RSA -keysize 4096 -validity 10000 `
  -alias smart_recycle
```

คัดลอกตัวอย่าง:

```powershell
Copy-Item android\key.properties.example android\key.properties
```

แก้ `storeFile`, `storePassword`, `keyPassword` และ `keyAlias` ให้ตรงกับ Keystore จริง
จากนั้นรัน:

```powershell
flutter build apk --release
```

ห้าม Commit ไฟล์เหล่านี้:

- `android/key.properties`
- `*.jks` และ `*.keystore`
- รหัสผ่าน Keystore

## ตรวจสอบหลังติดตั้ง

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

