import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ApiClient {
  ApiClient._();

  static String get baseUrl => ApiConfig.baseUrl;
  static const _storage = FlutterSecureStorage();

  static Future<Map<String, String>> _headers({bool jsonBody = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (jsonBody) {
      headers['Content-Type'] = 'application/json';
    }

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      debugPrint('ApiClient: failed to read auth token: $e');
    }

    return headers;
  }

  static Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath').replace(queryParameters: queryParameters);
  }

  static Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final res = await http.get(
      _uri(path, queryParameters),
      headers: await _headers(jsonBody: false),
    );

    return _decode(res);
  }

  static Future<dynamic> post(
    String path, {
    Map<String, String>? queryParameters,
    Object? body,
  }) async {
    final res = await http.post(
      _uri(path, queryParameters),
      headers: await _headers(jsonBody: true),
      body: jsonEncode(body ?? const {}),
    );

    return _decode(res);
  }

  static Future<dynamic> put(
    String path, {
    Map<String, String>? queryParameters,
    Object? body,
  }) async {
    final res = await http.put(
      _uri(path, queryParameters),
      headers: await _headers(jsonBody: true),
      body: jsonEncode(body ?? const {}),
    );

    return _decode(res);
  }

  static Future<dynamic> delete(
    String path, {
    Map<String, String>? queryParameters,
    Object? body,
  }) async {
    final res = await http.delete(
      _uri(path, queryParameters),
      headers: await _headers(jsonBody: true),
      body: body == null ? null : jsonEncode(body),
    );

    return _decode(res);
  }

  static dynamic _decode(http.Response res) {
    final status = res.statusCode;
    final text = res.body;

    dynamic decoded;
    try {
      decoded = text.isEmpty ? null : jsonDecode(text);
    } catch (_) {
      decoded = text;
    }

    if (status >= 200 && status < 300) {
      return decoded;
    }

    final message = decoded is Map<String, dynamic>
        ? (decoded['message']?.toString() ?? decoded['error']?.toString() ?? 'Request failed')
        : 'Request failed';

    throw Exception('API $status: $message');
  }
}