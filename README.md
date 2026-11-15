# Encore

A live events diary for the Entertainment and Lifestyle area. You plan the concerts, plays, comedy nights, festivals and matches you want to go to. Afterwards you log them with a rating, the ticket price and notes. The home screen shows your year: how many shows you've seen, how much you've spent and your average rating. The Discover tab lists upcoming shows around Sri Lanka, and one tap adds a show to your plans.

### Why people would use it

- **Ticket stubs get lost.** Encore keeps one record of every show you've been to, with your rating and notes, so you can look back on a year of live events.
- **Plans slip.** The Upcoming tab lists dates you've committed to, and the home screen reminds you to log a show once its date has passed.
- **Money adds up.** You can see what you've spent on tickets this year at a glance.
- **Finding things to do.** Discover gathers concerts, theatre, comedy, festivals and matches in one place, instead of scattered Facebook posts.
- **Patchy signal at venues.** Everything still works offline and syncs when you're back online.

- `backend/`: Node.js + Express REST API with SQLite (`node:sqlite`, built into Node 22.13+)
- `app/`: Flutter app (Riverpod for state, Hive for offline storage, `http` for the API)

## Run the backend

```bash
cd backend
npm install
npm test
npm start
```

The API runs on port 3000. The data goes into `encore.db`, or wherever `DB_PATH` points.

On start the server creates four demo accounts if they are missing (set `DEMO_DATA=off` to skip this). They all use the password `encore2026`:

| Email | What is in it |
|---|---|
| sayuru@encore.lk | 6 shows from 2026 in the diary with ratings and notes, 3 upcoming plans |
| nethmi@encore.lk | 2 diary entries, 2 plans |
| kavindu@encore.lk | 2 diary entries, 3 plans |
| dilini@encore.lk | 2 diary entries, 2 plans |

The ratings and notes are made up for the demo.

| Method | Path | What it does |
|---|---|---|
| POST | /auth/register | Create an account and get a token |
| POST | /auth/login | Log in and get a token |
| POST | /auth/logout | End the session |
| GET / PUT | /me | Read your profile or change your name |
| GET | /events | List your events |
| GET | /events/:id | Get one event |
| POST | /events | Create an event (the client picks the id, so a retry never makes a duplicate) |
| PUT | /events/:id | Update an event. Sends back 409 if the server already has a newer edit |
| DELETE | /events/:id | Delete an event. A retry is safe |
| GET | /shows?type= | Public upcoming listings for Discover (no login needed) |
| GET | /images/:file | Banner images for the listings |

The Discover listings live in `backend/shows.json`, because no free public API covers Sri Lankan events (Ticketmaster and Eventbrite list none here). There are two kinds:

- `real-*`: shows that took place in Sri Lanka in 2026, such as the Ceylon Music Festival with Arash and Mohombi, Russell Peters at City of Dreams and DJ Snake at Senter. The names, dates, venues and line-ups come from news reports in the Sunday Times, Daily FT and Newsfirst. Ticket prices for Russell Peters and the Ceylon Music Festival are the reported starting prices. The others are estimates.
- `show-*`: upcoming listings at real venues, but the events are made up.

These appear in Discover as "Earlier this year", where "I went" adds a show straight to your diary. The photos are from Wikimedia Commons, and their credits are in `backend/public/images/CREDITS.md`.

## Hosting the API for free

`render.yaml` sets up the backend on Render's free plan:

1. Sign in at render.com with GitHub.
2. Choose New, then Blueprint, and pick this repository.
3. Once it is live, build the app against its URL (see below).

The free plan sleeps after 15 minutes idle, and the first request then takes around 30 to 50 seconds. It also has no persistent disk, so the SQLite file resets on each restart. The demo accounts come back on every boot, but any account you register yourself is lost. Vercel is a poor fit because it runs functions with no long-lived process or writable disk, so SQLite sessions would not survive between requests.

## Run the app

```bash
cd app
flutter pub get
flutter test
flutter run
```

On the Android emulator the app talks to `http://10.0.2.2:3000`, which is your computer's localhost.

For a release APK, deploy the backend first (Render, Railway or similar), then:

```bash
flutter build apk --release --dart-define=API_URL=https://your-api.example.com
```

The Android manifest already has the INTERNET permission and allows plain `http://` for local testing.

## How offline works

1. Every create, edit and delete goes to Hive on the phone first. It's also added to a queue box.
2. The app then tries to sync. It sends each queued change in order, then pulls `GET /events`, which replaces the local copy.
3. If there's no network, the queue stays put. A banner shows how many changes are waiting, and a Retry button (or pull to refresh) tries again.
4. Conflicts: the newer edit wins. The server rejects an older edit with 409, and the pull that follows brings in the server's newer version.
5. A saved login opens the app straight away, so you can see and change your events with no internet at all.

## Project layout (MVVM)

```
lib/
  core/       api_client.dart (HTTP + error types), validators.dart
  data/       event.dart (models), local_store.dart (Hive), repositories.dart (auth + offline sync)
  state/      providers.dart (Riverpod notifiers, the view models)
  ui/
    screens/  auth, home_shell, dashboard, discover, show_detail, event_list, event_detail, event_form, profile
    widgets/  ticket_stub (custom painted ticket), star_rating, sync_banner, banner_image
```
