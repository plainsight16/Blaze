import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_session.dart';
import '../config/api_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final Object? body;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.session});

  final AuthSession session;

  Uri _uri(String path) => Uri.parse('$apiBaseUrl$path');

  Map<String, String> _headers({bool auth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = session.accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final res = await http.post(
      _uri(path),
      headers: _headers(auth: auth),
      body: jsonEncode(body ?? const <String, dynamic>{}),
    );

    final decoded = _decode(res);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        decoded['message']?.toString() ??
            decoded['detail']?.toString() ??
            'Request failed',
        statusCode: res.statusCode,
        body: decoded,
      );
    }

    return decoded;
  }

  Future<Map<String, dynamic>> postJsonNoBody(
    String path, {
    bool auth = true,
  }) async {
    final res = await http.post(
      _uri(path),
      headers: _headers(auth: auth),
      body: jsonEncode(const <String, dynamic>{}),
    );

    final decoded = _decode(res);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        decoded['message']?.toString() ??
            decoded['detail']?.toString() ??
            'Request failed',
        statusCode: res.statusCode,
        body: decoded,
      );
    }

    return decoded;
  }

  Future<dynamic> getJson(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final uri = _uri(path).replace(queryParameters: query);
    final res = await http.get(uri, headers: _headers(auth: auth));

    final decoded = _decode(res);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        decoded['message']?.toString() ??
            decoded['detail']?.toString() ??
            'Request failed',
        statusCode: res.statusCode,
        body: decoded,
      );
    }

    return decoded;
  }

  Map<String, dynamic> _decode(http.Response res) {
    final text = res.body;
    if (text.isEmpty) return const <String, dynamic>{};

    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is List) return <String, dynamic>{'data': decoded};
    return <String, dynamic>{'data': decoded};
  }
}
