import 'dart:convert';
import 'dart:io';

import 'package:encore/core/api_client.dart';
import 'package:encore/core/validators.dart' as v;
import 'package:encore/data/event.dart';
import 'package:encore/data/local_store.dart';
import 'package:encore/data/repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final event = EventItem(id: 'e1', title: 'Jazz Night', date: DateTime(2026, 12, 1, 19), updatedAt: DateTime.utc(2026, 11, 1));

  test('event survives a JSON round trip', () {
    final back = EventItem.fromJson(event.toJson());
    expect(back.title, 'Jazz Night');
    expect(back.date, event.date);
    expect(back.updatedAt, event.updatedAt);
    // a date from the server with an offset must come back as local time, not UTC
    final fromServer = EventItem.fromJson({...event.toJson(), 'date': '2026-10-31T19:00:00+05:30'});
    expect(fromServer.date.isUtc, isFalse);
    expect(fromServer.date, DateTime.utc(2026, 10, 31, 13, 30).toLocal());
  });

  test('validators', () {
    expect(v.requiredText('  '), isNotNull);
    expect(v.email('a@b.co'), isNull);
    expect(v.email('nope'), isNotNull);
    expect(v.price('-1'), isNotNull);
    expect(v.price(''), isNull);
    expect(v.attendedDate('attended', DateTime.now().add(const Duration(days: 1))), isNotNull);
    expect(v.attendedDate('planned', DateTime.now().add(const Duration(days: 1))), isNull);
  });

  test('changes made offline are queued, then sent when back online', () async {
    final dir = await Directory.systemTemp.createTemp('encore');
    final store = LocalStore();
    await store.open(path: dir.path);

    var online = false;
    final server = <String, Map<String, dynamic>>{};
    final calls = <String>[];
    final client = MockClient((req) async {
      if (!online) throw const SocketException('no network');
      calls.add('${req.method} ${req.url.path}');
      if (req.method == 'POST') {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        server[body['id'] as String] = body;
        return http.Response(req.body, 201);
      }
      return http.Response(jsonEncode(server.values.toList()), 200);
    });
    final repo = EventRepository(ApiClient(client: client), store);

    await repo.save(event, isNew: true);
    expect(await repo.sync(), isFalse, reason: 'offline');
    expect(repo.pendingCount, 1);
    expect(repo.cached().single.title, 'Jazz Night', reason: 'still visible offline');

    online = true;
    expect(await repo.sync(), isTrue);
    expect(repo.pendingCount, 0);
    expect(calls, ['POST /events', 'GET /events']);
    expect(server.containsKey('e1'), isTrue);

    await dir.delete(recursive: true);
  });
}
