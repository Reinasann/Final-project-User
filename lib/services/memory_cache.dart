import 'dart:async';

typedef CacheClock = DateTime Function();

/// In-memory stale-while-revalidate cache with request de-duplication.
class MemoryCache<T> {
  final Duration maxAge;
  final void Function()? onUpdated;
  final CacheClock _clock;

  T? _value;
  bool _hasValue = false;
  DateTime? _updatedAt;
  Future<T>? _inFlight;

  MemoryCache({
    required this.maxAge,
    this.onUpdated,
    CacheClock? clock,
  }) : _clock = clock ?? DateTime.now;

  bool get hasValue => _hasValue;
  T? get valueOrNull => _hasValue ? _value : null;

  bool get isStale =>
      !_hasValue ||
      _updatedAt == null ||
      !_clock().isBefore(_updatedAt!.add(maxAge));

  Future<T> get(
    Future<T> Function() loader, {
    bool forceRefresh = false,
  }) {
    if (!forceRefresh && _hasValue) {
      if (isStale) _refreshInBackground(loader);
      return Future<T>.value(_value as T);
    }
    return _refresh(loader);
  }

  Future<void> refreshIfStale(Future<T> Function() loader) async {
    if (!_hasValue || !isStale) return;
    await _refresh(loader);
  }

  void setValue(T value) {
    _value = value;
    _hasValue = true;
    _updatedAt = _clock();
    onUpdated?.call();
  }

  void invalidate() {
    _value = null;
    _hasValue = false;
    _updatedAt = null;
  }

  Future<T> _refresh(Future<T> Function() loader) {
    final existing = _inFlight;
    if (existing != null) return existing;

    late final Future<T> request;
    request = Future<T>.sync(loader).then((value) {
      setValue(value);
      return value;
    }).whenComplete(() {
      if (identical(_inFlight, request)) _inFlight = null;
    });
    _inFlight = request;
    return request;
  }

  void _refreshInBackground(Future<T> Function() loader) {
    unawaited(
      _refresh(loader).then<void>((_) {}).catchError((Object _) {}),
    );
  }
}
