import 'package:hive_flutter/hive_flutter.dart';

import 'event.dart';

/// Everything kept on the phone. Hive stores plain maps, so no code generation is needed.
class LocalStore {
  late final Box _events; // id -> event json
  late final Box _queue; // auto keys -> {op, id, data}, in the order they happened
  late final Box _session; // token, user
  late final Box _shows; // last Discover listing, for offline browsing

  /// [path] is only for tests, which have no Flutter app folder.
  Future<void> open({String? path}) async {
    if (path == null) {
      await Hive.initFlutter();
    } else {
      Hive.init(path);
    }
    _events = await Hive.openBox('events');
    _queue = await Hive.openBox('queue');
    _session = await Hive.openBox('session');
    _shows = await Hive.openBox('shows');
  }

  List<Show> shows() =>
      (_shows.get('list', defaultValue: []) as List).map((j) => Show.fromJson(Map<String, dynamic>.from(j as Map))).toList();
  Future<void> saveShows(List<Show> list) => _shows.put('list', [for (final s in list) s.toJson()]);

  // events
  List<EventItem> events() =>
      _events.values.map((e) => EventItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  Future<void> putEvent(EventItem e) => _events.put(e.id, e.toJson());
  Future<void> removeEvent(String id) => _events.delete(id);
  Future<void> replaceEvents(List<EventItem> list) async {
    await _events.clear();
    await _events.putAll({for (final e in list) e.id: e.toJson()});
  }

  // sync queue
  Future<void> enqueue(String op, String id, [Map<String, dynamic>? data]) =>
      _queue.add({'op': op, 'id': id, 'data': data});
  List<MapEntry<dynamic, Map<String, dynamic>>> pending() => _queue.keys
      .map((k) => MapEntry(k, Map<String, dynamic>.from(_queue.get(k) as Map)))
      .toList();
  Future<void> dequeue(dynamic key) => _queue.delete(key);
  int get pendingCount => _queue.length;

  // session
  String? get token => _session.get('token') as String?;
  AppUser? get user {
    final u = _session.get('user');
    return u == null ? null : AppUser.fromJson(Map<String, dynamic>.from(u as Map));
  }

  Future<void> saveSession(String token, AppUser user) =>
      _session.putAll({'token': token, 'user': user.toJson()});
  Future<void> saveUser(AppUser user) => _session.put('user', user.toJson());

  /// On logout, wipe this user's data so the next person on the phone cannot see it.
  Future<void> clearAll() async {
    await _events.clear();
    await _queue.clear();
    await _session.clear();
  }
}
