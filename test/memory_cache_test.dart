import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:recycle_admin/services/memory_cache.dart';

void main() {
  test('returns fresh cached data without calling the loader again', () async {
    var now = DateTime(2026, 8, 23, 12);
    var calls = 0;
    final cache = MemoryCache<String>(
      maxAge: const Duration(minutes: 1),
      clock: () => now,
    );

    Future<String> loader() async => 'ข้อมูลครั้งที่ ${++calls}';

    expect(await cache.get(loader), 'ข้อมูลครั้งที่ 1');
    now = now.add(const Duration(seconds: 30));
    expect(await cache.get(loader), 'ข้อมูลครั้งที่ 1');
    expect(calls, 1);
  });

  test('returns stale data immediately and refreshes it in background',
      () async {
    var now = DateTime(2026, 8, 23, 12);
    var calls = 0;
    var updates = 0;
    final cache = MemoryCache<String>(
      maxAge: const Duration(minutes: 1),
      clock: () => now,
      onUpdated: () => updates++,
    );

    Future<String> loader() async => 'ข้อมูลครั้งที่ ${++calls}';

    expect(await cache.get(loader), 'ข้อมูลครั้งที่ 1');
    now = now.add(const Duration(minutes: 2));
    expect(await cache.get(loader), 'ข้อมูลครั้งที่ 1');
    await Future<void>.delayed(Duration.zero);

    expect(await cache.get(loader), 'ข้อมูลครั้งที่ 2');
    expect(calls, 2);
    expect(updates, 2);
  });

  test('coalesces concurrent requests into one loader call', () async {
    final completer = Completer<String>();
    var calls = 0;
    final cache = MemoryCache<String>(
      maxAge: const Duration(minutes: 1),
    );

    Future<String> loader() {
      calls++;
      return completer.future;
    }

    final first = cache.get(loader);
    final second = cache.get(loader, forceRefresh: true);
    expect(calls, 1);

    completer.complete('ข้อมูลร่วมกัน');
    expect(await first, 'ข้อมูลร่วมกัน');
    expect(await second, 'ข้อมูลร่วมกัน');
    expect(calls, 1);
  });

  test('invalidate requires the next read to load new data', () async {
    var calls = 0;
    final cache = MemoryCache<int>(
      maxAge: const Duration(minutes: 10),
    );

    Future<int> loader() async => ++calls;

    expect(await cache.get(loader), 1);
    cache.invalidate();
    expect(await cache.get(loader), 2);
  });

  test('keeps stale data when a background refresh fails', () async {
    var now = DateTime(2026, 8, 23, 12);
    final cache = MemoryCache<String>(
      maxAge: const Duration(minutes: 1),
      clock: () => now,
    );

    expect(await cache.get(() async => 'ข้อมูลเดิม'), 'ข้อมูลเดิม');
    now = now.add(const Duration(minutes: 2));
    expect(
      await cache.get(() async => throw Exception('เครือข่ายขัดข้อง')),
      'ข้อมูลเดิม',
    );
    await Future<void>.delayed(Duration.zero);

    expect(await cache.get(() async => 'ข้อมูลใหม่'), 'ข้อมูลเดิม');
    await Future<void>.delayed(Duration.zero);
    expect(await cache.get(() async => 'ไม่ถูกเรียก'), 'ข้อมูลใหม่');
  });
}
