import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../data/event.dart';
import '../data/local_store.dart';
import '../data/repositories.dart';

// Overridden in main() with the opened store.
final localStoreProvider = Provider<LocalStore>((ref) => throw UnimplementedError());
final apiClientProvider = Provider((ref) => ApiClient());

final authRepoProvider =
    Provider((ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(localStoreProvider)));
final eventRepoProvider =
    Provider((ref) => EventRepository(ref.watch(apiClientProvider), ref.watch(localStoreProvider)));

final showsProvider = FutureProvider.autoDispose(
    (ref) => ShowRepository(ref.watch(apiClientProvider), ref.watch(localStoreProvider)).load());

class AuthNotifier extends Notifier<AppUser?> {
  AuthRepository get _repo => ref.read(authRepoProvider);

  @override
  AppUser? build() => ref.read(authRepoProvider).savedUser;

  Future<void> login(String email, String password) async => state = await _repo.login(email, password);
  Future<void> register(String name, String email, String password) async =>
      state = await _repo.register(name, email, password);
  Future<void> updateName(String name) async => state = await _repo.updateName(name);

  Future<void> logout() async {
    await _repo.logout();
    ref.invalidate(eventsProvider);
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);

class EventsState {
  final List<EventItem> items;
  final bool online;
  final bool syncing;
  final int pending;
  const EventsState(this.items, {this.online = true, this.syncing = false, this.pending = 0});
}

class EventsNotifier extends Notifier<EventsState> {
  EventRepository get _repo => ref.read(eventRepoProvider);

  @override
  EventsState build() {
    Future.microtask(sync);
    return EventsState(_sorted(ref.read(eventRepoProvider).cached()),
        pending: ref.read(eventRepoProvider).pendingCount);
  }

  List<EventItem> _sorted(List<EventItem> list) => list..sort((a, b) => a.date.compareTo(b.date));

  void _refresh({bool? online, bool syncing = false}) => state = EventsState(_sorted(_repo.cached()),
      online: online ?? state.online, syncing: syncing, pending: _repo.pendingCount);

  Future<void> sync() async {
    if (state.syncing) return;
    state = EventsState(state.items, online: state.online, syncing: true, pending: state.pending);
    bool online;
    var failed = false;
    try {
      online = await _repo.sync();
    } catch (_) {
      // shortcut: server errors (including 401) just keep the queue; tokens never expire on our API
      online = state.online;
      failed = true;
    }
    _refresh(online: online);
    // a change made while we were syncing still needs sending
    if (online && !failed && _repo.pendingCount > 0) sync();
  }

  Future<void> save(EventItem e, {required bool isNew}) async {
    await _repo.save(e, isNew: isNew);
    _refresh();
    sync();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _refresh();
    sync();
  }
}

final eventsProvider = NotifierProvider<EventsNotifier, EventsState>(EventsNotifier.new);

EventItem? findEvent(EventsState s, String id) {
  for (final e in s.items) {
    if (e.id == id) return e;
  }
  return null;
}
