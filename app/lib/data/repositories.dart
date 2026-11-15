import '../core/api_client.dart';
import 'event.dart';
import 'local_store.dart';

class AuthRepository {
  AuthRepository(this._api, this._local) {
    _api.token = _local.token;
  }

  final ApiClient _api;
  final LocalStore _local;

  AppUser? get savedUser => _local.user;

  Future<AppUser> login(String email, String password) =>
      _signIn('/auth/login', {'email': email.trim(), 'password': password});

  Future<AppUser> register(String name, String email, String password) =>
      _signIn('/auth/register', {'name': name.trim(), 'email': email.trim(), 'password': password});

  Future<AppUser> _signIn(String path, Map<String, dynamic> body) async {
    final res = await _api.post(path, body) as Map<String, dynamic>;
    final user = AppUser.fromJson(res['user'] as Map<String, dynamic>);
    _api.token = res['token'] as String;
    await _local.saveSession(_api.token!, user);
    return user;
  }

  Future<AppUser> updateName(String name) async {
    final user = AppUser.fromJson(await _api.put('/me', {'name': name.trim()}) as Map<String, dynamic>);
    await _local.saveUser(user);
    return user;
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout', {});
    } catch (_) {
      // still log out on the phone if the server cannot be reached
    }
    _api.token = null;
    await _local.clearAll();
  }
}

/// Offline first: every change is written to the phone and queued, then the queue
/// is sent to the server when it can be reached.
class EventRepository {
  EventRepository(this._api, this._local);

  final ApiClient _api;
  final LocalStore _local;

  List<EventItem> cached() => _local.events();
  int get pendingCount => _local.pendingCount;

  Future<void> save(EventItem e, {required bool isNew}) async {
    await _local.putEvent(e);
    await _local.enqueue(isNew ? 'create' : 'update', e.id, e.toJson());
  }

  Future<void> delete(String id) async {
    await _local.removeEvent(id);
    await _local.enqueue('delete', id);
  }

  /// Sends queued changes, then pulls the server copy. Returns false when offline.
  Future<bool> sync() async {
    try {
      for (final entry in _local.pending()) {
        await _push(entry.value);
        await _local.dequeue(entry.key);
      }
      final list = (await _api.get('/events') as List)
          .map((j) => EventItem.fromJson(j as Map<String, dynamic>))
          .toList();
      await _local.replaceEvents(list);
      // anything the user changed while we were syncing is still queued: keep it on screen
      for (final job in _local.pending().map((e) => e.value)) {
        job['op'] == 'delete'
            ? await _local.removeEvent(job['id'] as String)
            : await _local.putEvent(EventItem.fromJson(Map<String, dynamic>.from(job['data'] as Map)));
      }
      return true;
    } on OfflineException {
      return false; // queue stays, try again next time
    }
  }

  Future<void> _push(Map<String, dynamic> job) async {
    final id = job['id'] as String;
    final data = job['data'] == null ? null : Map<String, dynamic>.from(job['data'] as Map);
    try {
      switch (job['op']) {
        case 'create':
          await _api.post('/events', data!);
        case 'update':
          await _api.put('/events/$id', data!);
        case 'delete':
          await _api.delete('/events/$id');
      }
    } on ApiException catch (e) {
      // 409: the server has a newer edit, so it wins. 404: deleted elsewhere.
      // 400: the server rejected the data, and retrying forever would block the queue.
      // In all three cases the pull after the queue puts the phone back in line with the server.
      if (e.status != 409 && e.status != 404 && e.status != 400) rethrow;
    }
  }
}

class ShowRepository {
  ShowRepository(this._api, this._local);

  final ApiClient _api;
  final LocalStore _local;

  /// Fresh listings when online, the last saved ones when offline.
  Future<({List<Show> shows, bool offline})> load() async {
    try {
      final list = (await _api.get('/shows') as List).map((j) => Show.fromJson(j as Map<String, dynamic>)).toList();
      await _local.saveShows(list);
      return (shows: list, offline: false);
    } on OfflineException {
      return (shows: _local.shows(), offline: true);
    }
  }
}
