import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// The server returned an error with a stable code, such as `moodle_invalid_credentials`.
class ApiException implements Exception {
  const ApiException(this.status, this.code);

  /// HTTP status code, for example 401 or 404.
  final int status;

  /// Error code from the server's `error` field, for example `no_account`.
  final String code;

  @override
  String toString() => 'ApiException($status, $code)';
}

/// The request never completed: no connection, timeout, or DNS failure.
class NetworkException implements Exception {
  const NetworkException();

  @override
  String toString() => 'NetworkException';
}

/// Sends requests to the KLAESP server and turns the replies into data or errors.
class ApiClient {
  /// Uses the given HTTP client, or creates one. Passing a client makes the class easy to test.
  ApiClient({http.Client? client}) {
    _client = client ?? http.Client();
  }

  late final http.Client _client;

  /// Sends a POST request with a JSON body and returns the decoded JSON reply.
  /// Pass [sessionToken] for routes that need a signed-in user.
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    String? sessionToken,
  }) {
    return _send('POST', path, body: body, sessionToken: sessionToken);
  }

  /// Sends a GET request and returns the decoded JSON reply.
  Future<Map<String, dynamic>> get(String path, {String? sessionToken}) {
    return _send('GET', path, sessionToken: sessionToken);
  }

  /// Sends a DELETE request. Ignores the reply body, and throws on errors.
  Future<void> delete(String path, {String? sessionToken}) async {
    await _send('DELETE', path, sessionToken: sessionToken);
  }

  /// Shared logic for every request. Builds the request, sends it with a 30-second limit,
  /// decodes the JSON reply, and throws [ApiException] for error status codes.
  /// Throws [NetworkException] when the request never completes.
  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? sessionToken,
  }) async {
    // Build the full URL and headers. Add the session token and JSON body when given.
    final uri = Uri.parse('$apiBaseUrl$path');
    final request = http.Request(method, uri)
      ..headers['accept'] = 'application/json'
      ..headers['content-type'] = 'application/json';
    if (sessionToken != null) {
      request.headers['authorization'] = 'Bearer $sessionToken';
    }
    if (body != null) {
      request.body = jsonEncode(body);
    }

    // Send and read the full reply. Any failure here means the server was never reached.
    final http.Response response;
    try {
      final streamed =
          await _client.send(request).timeout(const Duration(seconds: 30));
      response = await http.Response.fromStream(streamed);
    } catch (_) {
      throw const NetworkException();
    }

    // Decode the body as JSON. Empty or non-JSON bodies become an empty map.
    Map<String, dynamic> json = {};
    if (response.body.isNotEmpty) {
      try {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        // Non-JSON error bodies fall through to the status check below.
      }
    }

    // 400 and above are errors. Use the server's error code, or a generic one.
    if (response.statusCode >= 400) {
      throw ApiException(
        response.statusCode,
        json['error'] as String? ?? 'unknown_error',
      );
    }
    return json;
  }
}
