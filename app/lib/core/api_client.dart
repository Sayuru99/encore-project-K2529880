import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

// Pass your hosted URL at build time: flutter build apk --dart-define=API_URL=https://...
// 10.0.2.2 is how the Android emulator reaches localhost on your computer.
const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:3000');

/// Images from the API come as paths like /images/x.jpg.
String imageUrl(String path) => path.startsWith('http') ? path : '$apiUrl$path';

/// The server could not be reached (no internet, server down, timeout).
class OfflineException implements Exception {
  @override
  String toString() => 'You are offline. Changes are saved on this phone and will sync later.';
}

/// The server answered with an error status or a body we could not read.
class ApiException implements Exception {
  final int status;
  final String message;
  final Map<String, dynamic>? body;
  ApiException(this.status, this.message, [this.body]);
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? token;

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, Object body) => _send('POST', path, body);
  Future<dynamic> put(String path, Object body) => _send('PUT', path, body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    final req = http.Request(method, Uri.parse('$apiUrl$path'))
      ..headers['Content-Type'] = 'application/json';
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    if (body != null) req.body = jsonEncode(body);

    final http.Response res;
    try {
      res = await http.Response.fromStream(
          await _client.send(req).timeout(const Duration(seconds: 8)));
    } on SocketException {
      throw OfflineException();
    } on TimeoutException {
      throw OfflineException();
    } on http.ClientException {
      throw OfflineException();
    }

    if (res.statusCode == 204) return null;
    final dynamic json;
    try {
      json = jsonDecode(res.body);
    } on FormatException {
      throw ApiException(res.statusCode, 'The server sent a response the app could not read.');
    }
    if (res.statusCode >= 400) {
      final map = json is Map<String, dynamic> ? json : null;
      throw ApiException(res.statusCode, map?['error']?.toString() ?? 'Request failed (${res.statusCode})', map);
    }
    return json;
  }
}
