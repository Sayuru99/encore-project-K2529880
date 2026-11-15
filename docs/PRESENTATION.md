# Encore: presentation walkthrough (10 minutes)

Speaker notes for the CW2 presentation. Each part says what to have on screen and what to say. File links open at the right line in VS Code or on GitHub.

Before you start:

- Backend running (`cd backend && npm start`) or the Render URL awake (open `/health` a minute before).
- Phone or emulator logged in as **sayuru@encore.lk / encore2026**.
- VS Code open on the repo with these files in tabs: `providers.dart`, `repositories.dart`, `api_client.dart`, `server.js`, `ticket_stub.dart`.

| Part | Time | Topic |
|---|---|---|
| 1 | 0:00 | The idea |
| 2 | 1:00 | Main features |
| 3 | 2:30 | Implementation: backend, libraries, state, offline |
| 4 | 5:30 | Live demo |
| 5 | 8:00 | Code walkthrough |
| 6 | 9:30 | Wrap up |

---

## 1. The idea (1 min)

**Screen:** Login screen on the phone, or slide 1.

Say:

- My area is 4, Entertainment and Lifestyle (ID 2529880, digit sum 34, 34 mod 5 = 4).
- Encore is a diary for live events: concerts, plays, comedy, festivals and matches.
- The problem: ticket stubs get lost, plans slip, ticket money adds up, and venue signal is bad.
- Ticket apps care about the moment you pay. Encore covers before and after: you plan, you go, you rate, and you see your year.

---

## 2. Main features (1.5 min)

**Screen:** Log in as sayuru@encore.lk and land on Home.

| Show this | Say this | Screen file |
|---|---|---|
| Purple stats card | Year in numbers: shows seen, LKR spent, average rating | [dashboard_screen.dart](../app/lib/ui/screens/dashboard_screen.dart) |
| Next up ticket | Custom ticket stub widget, I'll show the code later | [ticket_stub.dart](../app/lib/ui/widgets/ticket_stub.dart) |
| Discover tab | Real 2026 shows like Mohombi at Port City, plus upcoming listings | [discover_screen.dart](../app/lib/ui/screens/discover_screen.dart) |
| Upcoming and Diary tabs | Planned and attended events, with search and type filters | [event_list_screen.dart](../app/lib/ui/screens/event_list_screen.dart) |
| Profile tab | Change name, sync status, safe logout | [profile_screen.dart](../app/lib/ui/screens/profile_screen.dart) |

There are nine screens in total: auth, home shell, dashboard, discover, show detail, event list, event detail, event form and profile.

---

## 3. Implementation (3 min)

### 3a. Architecture (45 s)

**Screen:** [docs/diagrams/architecture.png](diagrams/architecture.png)

- It's MVVM in layers. Screens only draw and forward taps.
- Riverpod notifiers are the view models.
- Repositories decide between the phone and the server.
- `LocalStore` wraps Hive and `ApiClient` wraps HTTP.

Folders: `core/`, `data/`, `state/`, `ui/screens`, `ui/widgets`.

### 3b. Backend and REST API (45 s)

**Screen:** [backend/server.js](../backend/server.js)

| Lines | Point |
|---|---|
| [server.js:15-25](../backend/server.js#L15-L25) | SQLite tables: users, sessions, events. Uses `node:sqlite`, which is built into Node |
| [server.js:67-81](../backend/server.js#L67-L81) | Register: scrypt hash with a random salt |
| [server.js:91-98](../backend/server.js#L91-L98) | Auth middleware: Bearer token, every route below needs it |
| [server.js:128-142](../backend/server.js#L128-L142) | POST /events: the phone sends the id, so a retry returns 200, not a duplicate |
| [server.js:144-159](../backend/server.js#L144-L159) | PUT /events/:id: returns 409 if the edit is older than the server copy |
| [server.js:162-165](../backend/server.js#L162-L165) | DELETE always returns 204, so it's safe to repeat |
| [backend/seed.js](../backend/seed.js) | Demo accounts recreated on every boot, because free hosting wipes the disk |

### 3c. Third-party libraries (30 s)

**Screen:** [app/pubspec.yaml](../app/pubspec.yaml)

- **flutter_riverpod:** state without a BuildContext, and easy to test.
- **hive:** fast offline storage with plain maps, so no code generation.
- **http:** REST calls, with MockClient for tests.
- **uuid:** ids made on the phone.
- **cached_network_image:** images still show offline.
- **google_fonts** and **intl:** look and formatting.

### 3d. State management (30 s)

**Screen:** [app/lib/state/providers.dart](../app/lib/state/providers.dart)

| Lines | Point |
|---|---|
| [providers.dart:9-18](../app/lib/state/providers.dart#L9-L18) | Providers wire the store, the API client and the repositories |
| [providers.dart:40-46](../app/lib/state/providers.dart#L40-L46) | `EventsState`: items plus online, syncing and pending flags |
| [providers.dart:80-84](../app/lib/state/providers.dart#L80-L84) | `save()`: write locally, refresh the screen, then sync in the background |
| [main.dart:10-17](../app/lib/main.dart#L10-L17) | Hive opened once and injected with `overrideWithValue` |

### 3e. Offline and online (30 s)

**Screen:** [docs/diagrams/sync.png](diagrams/sync.png)

1. A change goes to Hive first, so the screen updates at once.
2. A job is added to the queue box.
3. Online: push the queue in order, pull `GET /events`, then re-apply anything still queued.
4. Offline: `OfflineException`. The queue stays and the banner shows "N changes waiting".
5. Conflicts: last write wins using `updatedAt`. The server answers 409 and its newer copy comes back on the pull.

---

## 4. Live demo (2.5 min)

Do these in order. Each step says what it proves.

| # | Do this on the phone | What it shows |
|---|---|---|
| 1 | Log out, tap **New here? Create an account**, submit with an empty name | Validation (`validators.dart`) |
| 2 | Log in as sayuru@encore.lk with the wrong password | Server error shown nicely (401 becomes "wrong email or password") |
| 3 | Log in properly and scroll Home | Stats from the 6 diary entries |
| 4 | **Discover**: swipe the carousel, tap the **concert** chip | Filtering |
| 5 | Scroll to **Earlier this year**, open **Ceylon Music Festival 2026** | Hero banner, real event data |
| 6 | Open **Upcoming**, tap **+**, add "Test Night", save with no name first | Form validation, then Create |
| 7 | Open it and edit the price | Update |
| 8 | **Turn on flight mode**, add another event | Offline: red banner, "1 change waiting to sync" |
| 9 | **Turn flight mode off**, tap **Retry** | Sync: banner disappears |
| 10 | Delete "Test Night" and confirm | Delete with a confirmation dialog |
| 11 | Open a past plan under "How did it go?", tap **I went**, give 4 stars | Moving a plan to the diary, star rating widget |

---

## 5. Code walkthrough (1.5 min)

Pick these three. They carry the most marks (data flow, offline, custom component).

### 5a. Sync, the heart of offline

[app/lib/data/repositories.dart:57-65](../app/lib/data/repositories.dart#L57-L65): save and delete only touch Hive and the queue.

[app/lib/data/repositories.dart:68-88](../app/lib/data/repositories.dart#L68-L88)

```dart
Future<bool> sync() async {
  try {
    for (final entry in _local.pending()) {   // 1. push queue in order
      await _push(entry.value);
      await _local.dequeue(entry.key);
    }
    final list = (await _api.get('/events') as List) ... ;   // 2. pull
    await _local.replaceEvents(list);
    for (final job in _local.pending().map((e) => e.value)) { ... }  // 3. keep edits made during sync
    return true;
  } on OfflineException {
    return false; // queue stays, try again next time
  }
}
```

Say: "The order matters. The phone pushes first, then pulls, so the server's view wins only after my changes are in."

[repositories.dart:102-107](../app/lib/data/repositories.dart#L102-L107): 409, 404 and 400 drop the job so one bad change can't block the queue.

### 5b. Error handling in one place

[app/lib/core/api_client.dart:47-70](../app/lib/core/api_client.dart#L47-L70)

- Socket error, timeout or client error becomes `OfflineException`, which takes the offline path.
- A bad JSON body or a status of 400 or above becomes `ApiException` with the server message, which is shown to the user.
- [api_client.dart:9](../app/lib/core/api_client.dart#L9): the API URL comes from `--dart-define`, so the same code works on the emulator and in the release APK.

### 5c. Custom component: TicketStub

[app/lib/ui/widgets/ticket_stub.dart](../app/lib/ui/widgets/ticket_stub.dart)

- [ticket_stub.dart:25-29](../app/lib/ui/widgets/ticket_stub.dart#L25-L29): one semantic label for screen readers, then `PhysicalShape` with a custom clipper.
- [ticket_stub.dart:84](../app/lib/ui/widgets/ticket_stub.dart#L84): `_TicketClipper` cuts the round notches.
- [ticket_stub.dart:102](../app/lib/ui/widgets/ticket_stub.dart#L102): `_PerforationPainter` draws the dashed tear line.
- It's used on Home, in both lists and on the detail screen, so it's reusable.

If time is left, show [sync_banner.dart:13](../app/lib/ui/widgets/sync_banner.dart#L13): the banner hides itself when the app is online with nothing pending.

---

## 6. Wrap up (30 s)

- **Tested:** 2 backend tests (`npm test`) and 5 Flutter tests (`flutter test`), all passing, plus 10 manual test cases on the device.
- **Limits:** login needs internet, tokens don't expire, free hosting resets SQLite, and Discover uses a JSON file because no Sri Lankan ticket site has a public API.
- **Next:** reminders the day before a show, sharing with friends, photos on diary entries.

---

## Likely viva questions

| Question | Short answer and where to point |
|---|---|
| Why Riverpod over Provider? | No BuildContext in view models, overridable in tests. [providers.dart](../app/lib/state/providers.dart) |
| What if the same create is sent twice? | Same id, so the server returns 200 with the existing row. [server.js:133-137](../backend/server.js#L133-L137) |
| What if two phones edit the same event? | Newer `updatedAt` wins, the older gets 409, and the pull brings the newer copy. [server.js:150-153](../backend/server.js#L150-L153) |
| What if the user edits while a sync is running? | That job is still queued, so it is re-applied after the pull. [repositories.dart:78-83](../app/lib/data/repositories.dart#L78-L83) |
| Where is validation? | Client: [validators.dart](../app/lib/core/validators.dart). Server: `validateEvent` in [server.js:41-51](../backend/server.js#L41-L51) |
| How are passwords stored? | scrypt with a random salt, compared with `timingSafeEqual`. [server.js:27](../backend/server.js#L27), [server.js:85](../backend/server.js#L85) |
| Why Hive and not sqflite? | Data is a simple list keyed by id. Plain maps need no schema or code generation. [local_store.dart](../app/lib/data/local_store.dart) |
| What happens on logout? | Token deleted on the server, all Hive boxes cleared so the next user sees nothing. [local_store.dart:60-64](../app/lib/data/local_store.dart#L60-L64) |
