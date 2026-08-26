import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static const _channel = AndroidNotificationChannel(
    'smart_recycle_alerts',
    'การแจ้งเตือน Smart Recycle',
    description: 'แจ้งเตือนถังเต็มและการตอบรับงาน',
    importance: Importance.max,
    playSound: true,
  );
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static StreamSubscription<String>? _tokenSubscription;
  static StreamSubscription<RemoteMessage>? _messageSubscription;
  static StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  static final StreamController<void> _notificationOpenController =
      StreamController<void>.broadcast();
  static bool _initialized = false;
  static bool _pendingNotificationOpen = false;

  static Stream<void> get notificationOpenRequests =>
      _notificationOpenController.stream;

  static bool consumePendingNotificationOpen() {
    final pending = _pendingNotificationOpen;
    _pendingNotificationOpen = false;
    return pending;
  }

  static bool get _supportsPush =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> initialize() async {
    if (!_supportsPush || _initialized) return;
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (_) => _requestOpenNotifications(),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
      unawaited(_showForegroundNotification(message));
      unawaited(_refreshNotifications());
    });
    _messageOpenedSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen((_) {
      _requestOpenNotifications();
      unawaited(_refreshNotifications());
    });
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _pendingNotificationOpen = true;
    _initialized = true;
  }

  static void _requestOpenNotifications() {
    if (_notificationOpenController.hasListener) {
      _notificationOpenController.add(null);
    } else {
      _pendingNotificationOpen = true;
    }
  }

  static Future<void> activateForCurrentUser() async {
    if (!_supportsPush) return;
    if (!_initialized) await initialize();
    final permission = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (permission.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) {
      await ApiService.registerPushToken(token);
    }
    await _tokenSubscription?.cancel();
    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) => unawaited(_registerTokenQuietly(newToken)),
    );
  }

  static Future<void> deactivateForCurrentUser() async {
    if (!_supportsPush || !_initialized) return;
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await ApiService.unregisterPushToken(token);
      } catch (_) {
        // การออกจากระบบต้องดำเนินต่อได้แม้เซิร์ฟเวอร์ไม่พร้อมใช้งาน
      }
    }
    await FirebaseMessaging.instance.deleteToken();
  }

  static Future<void> _registerTokenQuietly(String token) async {
    try {
      await ApiService.registerPushToken(token);
    } catch (_) {
      // ระบบจะลงทะเบียนใหม่เมื่อเข้าสู่ระบบหรือ FCM เปลี่ยนโทเคนครั้งถัดไป
    }
  }

  static Future<void> _refreshNotifications() async {
    try {
      await ApiService.notifications(forceRefresh: true);
    } catch (_) {
      // อาจได้รับข้อความก่อนเข้าสู่ระบบ จึงรอการรีเฟรชรอบถัดไป
    }
  }

  static Future<void> _showForegroundNotification(
    RemoteMessage message,
  ) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      id: message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'smart_recycle_alerts',
          'การแจ้งเตือน Smart Recycle',
          channelDescription: 'แจ้งเตือนถังเต็มและการตอบรับงาน',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      payload: message.data['notification_id'],
    );
  }

  static Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _messageOpenedSubscription?.cancel();
  }
}
