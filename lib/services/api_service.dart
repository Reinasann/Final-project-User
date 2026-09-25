import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import 'memory_cache.dart';

enum ApiResource {
  machines,
  profile,
  collections,
  notifications,
  issues,
  issueCategories,
}

/// Override with --dart-define=API_BASE_URL=http://YOUR_COMPUTER_IP:8000/api/v1
/// when testing against a local Django server.
class ApiService {
  ApiService._();

  static const _productionBaseUrl =
      'https://smart-recycle-admin.onrender.com/api/v1';
  static const _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const _requestTimeout = Duration(seconds: 30);
  static const _tokenStorageKey = 'smart_recycle_access_token';
  static const _userStorageKey = 'smart_recycle_user';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static String get baseUrl {
    final configured = _configuredBaseUrl.trim();
    final value = configured.isEmpty ? _productionBaseUrl : configured;
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static String? _token;
  static final StreamController<ApiResource> _cacheUpdates =
      StreamController<ApiResource>.broadcast();
  static final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();
  static bool _sessionExpiryNotified = false;

  static Stream<ApiResource> get cacheUpdates => _cacheUpdates.stream;
  static Stream<void> get sessionExpired => _sessionExpiredController.stream;

  static void _notify(ApiResource resource) => _cacheUpdates.add(resource);

  static final MemoryCache<List<Machine>> _machinesCache = MemoryCache(
    maxAge: const Duration(minutes: 1),
    onUpdated: () => _notify(ApiResource.machines),
  );
  static final MemoryCache<Map<String, dynamic>> _profileCache = MemoryCache(
    maxAge: const Duration(minutes: 10),
    onUpdated: () => _notify(ApiResource.profile),
  );
  static final MemoryCache<List<CollectionHistoryItem>> _collectionsCache =
      MemoryCache(
    maxAge: const Duration(minutes: 3),
    onUpdated: () => _notify(ApiResource.collections),
  );
  static final MemoryCache<List<NotificationItem>> _notificationsCache =
      MemoryCache(
    maxAge: const Duration(minutes: 1),
    onUpdated: () => _notify(ApiResource.notifications),
  );
  static final MemoryCache<List<IssueReportItem>> _issuesCache = MemoryCache(
    maxAge: const Duration(minutes: 3),
    onUpdated: () => _notify(ApiResource.issues),
  );
  static final MemoryCache<List<Map<String, dynamic>>> _categoriesCache =
      MemoryCache(
    maxAge: const Duration(minutes: 30),
    onUpdated: () => _notify(ApiResource.issueCategories),
  );

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static Future<Map<String, dynamic>?> restoreSession() async {
    try {
      final values = await Future.wait([
        _secureStorage.read(key: _tokenStorageKey),
        _secureStorage.read(key: _userStorageKey),
      ]);
      final savedToken = values[0];
      final savedUser = values[1];
      if (savedToken == null || savedToken.isEmpty || savedUser == null) {
        await clearSession();
        return null;
      }
      final decoded = jsonDecode(savedUser);
      if (decoded is! Map<String, dynamic>) {
        await clearSession();
        return null;
      }
      _token = savedToken;
      _sessionExpiryNotified = false;
      _profileCache.setValue(decoded);
      return decoded;
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await _post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(body['detail']?.toString() ?? 'เข้าสู่ระบบไม่สำเร็จ');
    }
    _clearCaches();
    _token = body['access_token'] as String;
    _sessionExpiryNotified = false;
    final user = body['user'] as Map<String, dynamic>;
    _profileCache.setValue(user);
    try {
      await Future.wait([
        _secureStorage.write(key: _tokenStorageKey, value: _token),
        _secureStorage.write(key: _userStorageKey, value: jsonEncode(user)),
      ]);
    } catch (_) {
      // การเข้าสู่ระบบยังใช้งานต่อได้ แม้อุปกรณ์ไม่รองรับ secure storage
    }
    return user;
  }

  static Future<void> logout() async {
    try {
      if (_token != null) {
        final response = await _post(
          Uri.parse('$baseUrl/auth/logout/'),
          headers: _headers,
        );
        _successBody(response, 'ไม่สามารถออกจากระบบได้');
      }
    } finally {
      await clearSession();
    }
  }

  static Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final response = await _post(
      Uri.parse('$baseUrl/auth/password-reset/request/'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return _successBody(response, 'ไม่สามารถส่งคำขอตั้งรหัสผ่านใหม่ได้');
  }

  static Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/auth/password-reset/confirm/'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'code': code,
        'new_password': newPassword,
      }),
    );
    _successBody(response, 'ไม่สามารถตั้งรหัสผ่านใหม่ได้');
  }

  static Future<List<Machine>> machines({bool forceRefresh = false}) {
    return _machinesCache.get(
      _fetchMachines,
      forceRefresh: forceRefresh,
    );
  }

  static Future<List<Machine>> _fetchMachines() async {
    final response =
        await _getResponse(Uri.parse('$baseUrl/machines/'), headers: _headers);
    final body = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
          body['detail']?.toString() ?? 'ไม่สามารถโหลดรายการเครื่องได้');
    }
    return (body['results'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Machine.fromApi)
        .toList();
  }

  static Future<Machine> machineDetail(
    String machineId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      for (final machine in _machinesCache.valueOrNull ?? const <Machine>[]) {
        if (machine.id == machineId) return machine;
      }
    }
    final response = await _getResponse(
      Uri.parse('$baseUrl/machines/$machineId/'),
      headers: _headers,
    );
    final machine = Machine.fromApi(
      _successBody(response, 'ไม่สามารถโหลดรายละเอียดเครื่องได้'),
    );
    _updateMachineCache(machine);
    return machine;
  }

  static Future<Machine> updateMachineStatus(
    String machineId,
    bool isOn,
  ) async {
    final response = await _patch(
      Uri.parse('$baseUrl/machines/$machineId/status/'),
      headers: _headers,
      body: jsonEncode({'is_on': isOn}),
    );
    final machine = Machine.fromApi(
      _successBody(response, 'ไม่สามารถเปลี่ยนสถานะเครื่องได้'),
    );
    _updateMachineCache(machine);
    return machine;
  }

  static void _updateMachineCache(Machine machine) {
    final cached = _machinesCache.valueOrNull;
    if (cached == null) return;
    final updated = [
      for (final item in cached)
        if (item.id == machine.id) machine else item,
    ];
    _machinesCache.setValue(updated);
  }

  static Future<Map<String, dynamic>> me({bool forceRefresh = false}) {
    return _profileCache.get(_fetchProfile, forceRefresh: forceRefresh);
  }

  static Future<void> registerPushToken(String token) async {
    final response = await _post(
      Uri.parse('$baseUrl/me/push-devices/register/'),
      headers: _headers,
      body: jsonEncode({'token': token, 'platform': 'android'}),
    );
    _successBody(response, 'ไม่สามารถลงทะเบียนการแจ้งเตือนของอุปกรณ์ได้');
  }

  static Future<void> unregisterPushToken(String token) async {
    final response = await _post(
      Uri.parse('$baseUrl/me/push-devices/unregister/'),
      headers: _headers,
      body: jsonEncode({'token': token}),
    );
    _successBody(response, 'ไม่สามารถยกเลิกการแจ้งเตือนของอุปกรณ์ได้');
  }

  static Future<Map<String, dynamic>> _fetchProfile() async {
    final response =
        await _getResponse(Uri.parse('$baseUrl/me/'), headers: _headers);
    final user = _successBody(response, 'ไม่สามารถโหลดข้อมูลผู้ใช้ได้');
    try {
      await _secureStorage.write(key: _userStorageKey, value: jsonEncode(user));
    } catch (_) {
      // ใช้ข้อมูลในหน่วยความจำต่อได้
    }
    return user;
  }

  static Future<Map<String, dynamic>> updateProfile(
    String name,
    String phone,
  ) async {
    final response = await _patch(
      Uri.parse('$baseUrl/me/profile/'),
      headers: _headers,
      body: jsonEncode({'name': name, 'phone': phone}),
    );
    final user = _successBody(response, 'ไม่สามารถบันทึกข้อมูลผู้ใช้ได้');
    _profileCache.setValue(user);
    return user;
  }

  static Future<void> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    final response = await _post(
      Uri.parse('$baseUrl/me/change-password/'),
      headers: _headers,
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );
    _successBody(response, 'ไม่สามารถเปลี่ยนรหัสผ่านได้');
  }

  static Future<List<CollectionHistoryItem>> collections({
    bool mine = true,
    bool forceRefresh = false,
  }) {
    if (!mine) return _fetchCollections(false);
    return _collectionsCache.get(
      () => _fetchCollections(true),
      forceRefresh: forceRefresh,
    );
  }

  static Future<List<CollectionHistoryItem>> _fetchCollections(
    bool mine,
  ) async {
    final body = await _get('$baseUrl/collections/${mine ? '?mine=1' : ''}',
        'ไม่สามารถโหลดประวัติการเก็บขยะได้');
    return _results(body).map(CollectionHistoryItem.fromApi).toList();
  }

  static Future<Map<String, dynamic>> createCollection(
    String machineId,
    String wasteType,
    double weightKg, {
    String? labelCode,
  }) async {
    final response = await _post(
      Uri.parse('$baseUrl/collections/create/'),
      headers: _headers,
      body: jsonEncode({
        'machine_id': machineId,
        'waste_type': wasteType,
        'weight_kg': weightKg,
        if (labelCode != null) 'label_code': labelCode,
      }),
    );
    final result = _successBody(response, 'ไม่สามารถบันทึกการเก็บขยะได้');
    _machinesCache.invalidate();
    _collectionsCache.invalidate();
    _notificationsCache.invalidate();
    return result;
  }

  static Future<List<NotificationItem>> notifications({
    bool forceRefresh = false,
  }) {
    return _notificationsCache.get(
      _fetchNotifications,
      forceRefresh: forceRefresh,
    );
  }

  static Future<List<NotificationItem>> _fetchNotifications() async {
    final body =
        await _get('$baseUrl/notifications/', 'ไม่สามารถโหลดการแจ้งเตือนได้');
    return _results(body).map(NotificationItem.fromApi).toList();
  }

  static Future<void> markNotificationRead(String notificationId) async {
    final response = await _post(
      Uri.parse('$baseUrl/notifications/$notificationId/read/'),
      headers: _headers,
    );
    _successBody(response, 'ไม่สามารถอัปเดตการแจ้งเตือนได้');
    _notificationsCache.invalidate();
  }

  static Future<Map<String, dynamic>> acknowledgeNotification(
    String notificationId,
  ) async {
    final response = await _post(
      Uri.parse('$baseUrl/notifications/$notificationId/acknowledge/'),
      headers: _headers,
    );
    final result = _successBody(response, 'ไม่สามารถตอบรับการแจ้งเตือนได้');
    _notificationsCache.invalidate();
    return result;
  }

  static Future<List<IssueReportItem>> issues({
    bool mine = true,
    bool forceRefresh = false,
  }) {
    if (!mine) return _fetchIssues(false);
    return _issuesCache.get(
      () => _fetchIssues(true),
      forceRefresh: forceRefresh,
    );
  }

  static Future<List<IssueReportItem>> _fetchIssues(bool mine) async {
    final body = await _get('$baseUrl/issues/${mine ? '?mine=1' : ''}',
        'ไม่สามารถโหลดรายการแจ้งปัญหาได้');
    return _results(body).map(IssueReportItem.fromApi).toList();
  }

  static Future<List<Map<String, dynamic>>> issueCategories({
    bool forceRefresh = false,
  }) {
    return _categoriesCache.get(
      _fetchIssueCategories,
      forceRefresh: forceRefresh,
    );
  }

  static Future<List<Map<String, dynamic>>> _fetchIssueCategories() async {
    final body = await _get(
      '$baseUrl/issue-categories/',
      'ไม่สามารถโหลดหัวข้อปัญหาได้',
    );
    return _results(body);
  }

  static Future<void> createIssue(
    String machineId,
    int categoryId,
    String description,
  ) async {
    final response = await _post(
      Uri.parse('$baseUrl/issues/create/'),
      headers: _headers,
      body: jsonEncode({
        'machine_id': machineId,
        'category_id': categoryId,
        'description': description,
      }),
    );
    _successBody(response, 'ไม่สามารถส่งรายงานปัญหาได้');
    _issuesCache.invalidate();
    _notificationsCache.invalidate();
  }

  static Future<void> refreshStaleCaches() async {
    await Future.wait([
      _refreshQuietly(() => _machinesCache.refreshIfStale(_fetchMachines)),
      _refreshQuietly(() => _profileCache.refreshIfStale(_fetchProfile)),
      _refreshQuietly(
        () => _collectionsCache.refreshIfStale(() => _fetchCollections(true)),
      ),
      _refreshQuietly(
        () => _notificationsCache.refreshIfStale(_fetchNotifications),
      ),
      _refreshQuietly(
        () => _issuesCache.refreshIfStale(() => _fetchIssues(true)),
      ),
      _refreshQuietly(
        () => _categoriesCache.refreshIfStale(_fetchIssueCategories),
      ),
    ]);
  }

  static Future<void> _refreshQuietly(Future<void> Function() refresh) async {
    try {
      await refresh();
    } catch (_) {
      // ใช้ข้อมูลเดิมต่อเมื่อการรีเฟรชเบื้องหลังล้มเหลว
    }
  }

  static Future<void> clearSession({bool notifyExpired = false}) async {
    _token = null;
    _clearCaches();
    try {
      await Future.wait([
        _secureStorage.delete(key: _tokenStorageKey),
        _secureStorage.delete(key: _userStorageKey),
      ]);
    } catch (_) {
      // ล้างสถานะในหน่วยความจำแล้ว จึงออกจากระบบต่อได้
    }
    if (notifyExpired && !_sessionExpiryNotified) {
      _sessionExpiryNotified = true;
      _sessionExpiredController.add(null);
    }
  }

  static void _clearCaches() {
    _machinesCache.invalidate();
    _profileCache.invalidate();
    _collectionsCache.invalidate();
    _notificationsCache.invalidate();
    _issuesCache.invalidate();
    _categoriesCache.invalidate();
  }

  static Future<Map<String, dynamic>> _get(
    String url,
    String fallbackMessage,
  ) async {
    final response = await _getResponse(Uri.parse(url), headers: _headers);
    return _successBody(response, fallbackMessage);
  }

  static Future<http.Response> _request(
    Future<http.Response> Function() operation,
  ) async {
    try {
      return await operation().timeout(_requestTimeout);
    } on TimeoutException {
      throw ApiException(
        'เซิร์ฟเวอร์ตอบสนองช้าเกินไป กรุณารอสักครู่แล้วลองอีกครั้ง',
      );
    } on http.ClientException {
      throw ApiException(
        'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาตรวจสอบอินเทอร์เน็ต',
      );
    }
  }

  static Future<http.Response> _getResponse(
    Uri uri, {
    Map<String, String>? headers,
  }) =>
      _request(() => http.get(uri, headers: headers));

  static Future<http.Response> _post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      _request(() => http.post(uri, headers: headers, body: body));

  static Future<http.Response> _patch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      _request(() => http.patch(uri, headers: headers, body: body));

  static List<Map<String, dynamic>> _results(Map<String, dynamic> body) {
    return (body['results'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  static Map<String, dynamic> _successBody(
    http.Response response,
    String fallbackMessage,
  ) {
    final body = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = body['detail']?.toString() ?? '';
      if (_token != null &&
          (response.statusCode == 401 ||
              (response.statusCode == 403 &&
                  detail.contains('หน่วยงานนี้ถูกระงับ')))) {
        unawaited(clearSession(notifyExpired: true));
      }
      throw ApiException(detail.isNotEmpty ? detail : fallbackMessage);
    }
    return body;
  }

  static Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on FormatException {
      return <String, dynamic>{};
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
