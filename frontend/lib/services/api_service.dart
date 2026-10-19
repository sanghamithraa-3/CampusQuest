import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/achievement.dart';
import '../models/user.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({
    FlutterSecureStorage? storage,
    http.Client? client,
    String? baseUrl,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _client = client ?? http.Client(),
       _baseUrl = (baseUrl ?? apiBaseUrl).replaceFirst(RegExp(r'/$'), '');

  static const _tokenKey = 'campus_quest_access_token';

  final FlutterSecureStorage _storage;
  final http.Client _client;
  final String _baseUrl;

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clearSession() => _storage.delete(key: _tokenKey);

  Future<User> login(String email, String password) async {
    final result = await _send(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
      authenticated: false,
    );
    await _storage.write(
      key: _tokenKey,
      value: result['accessToken'] as String,
    );
    return User.fromJson(result['user'] as Map<String, dynamic>);
  }

  Future<User> registerStudent(Map<String, dynamic> registration) async {
    final result = await _send(
      'POST',
      '/auth/register',
      body: registration,
      authenticated: false,
    );
    await _storage.write(
      key: _tokenKey,
      value: result['accessToken'] as String,
    );
    return User.fromJson(result['user'] as Map<String, dynamic>);
  }

  Future<User> currentUser() async {
    final result = await _send('GET', '/auth/me');
    return User.fromJson(result['user'] as Map<String, dynamic>);
  }

  Future<List<Achievement>> myAchievements() async {
    final result = await _send('GET', '/achievements');
    return (result['achievements'] as List<dynamic>)
        .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<User>> students() async {
    return _getAllPages('/admin/students', 'students', User.fromJson);
  }

  Future<List<Achievement>> allAchievements() async {
    return _getAllPages(
      '/admin/achievements',
      'achievements',
      Achievement.fromJson,
    );
  }

  Future<List<T>> _getAllPages<T>(
    String path,
    String key,
    T Function(Map<String, dynamic>) parse,
  ) async {
    const pageSize = 100;
    var page = 1;
    var total = 0;
    final items = <T>[];
    do {
      final result = await _send('GET', '$path?page=$page&limit=$pageSize');
      items.addAll(
        (result[key] as List<dynamic>).map(
          (item) => parse(item as Map<String, dynamic>),
        ),
      );
      final pagination = result['pagination'] as Map<String, dynamic>;
      total = pagination['total'] as int;
      page++;
    } while (items.length < total);
    return items;
  }

  Future<void> saveAchievement(
    Map<String, dynamic> details, {
    String? achievementId,
  }) async {
    await _send(
      achievementId == null ? 'POST' : 'PATCH',
      achievementId == null ? '/achievements' : '/achievements/$achievementId',
      body: details,
    );
  }

  Future<void> updateAchievement(
    String achievementId,
    Map<String, dynamic> details,
  ) async {
    await _send('PATCH', '/admin/achievements/$achievementId', body: details);
  }

  Future<void> deleteAchievement(
    String achievementId, {
    required bool asAdmin,
  }) async {
    await _send(
      'DELETE',
      '${asAdmin ? '/admin' : ''}/achievements/$achievementId',
    );
  }

  Future<void> setStudentActive(String id, bool isActive) async {
    await _send('PATCH', '/admin/students/$id', body: {'isActive': isActive});
  }

  Future<Map<String, dynamic>> portfolio({String? studentId}) async {
    final path = studentId == null
        ? '/portfolio/me'
        : '/portfolio/students/$studentId';
    return _send('GET', path);
  }

  Future<void> downloadPortfolio({String? studentId, String? filename}) async {
    final path = studentId == null
        ? '/portfolio/me/pdf'
        : '/portfolio/students/$studentId/pdf';
    final token = await readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please sign in again', statusCode: 401);
    }
    final response = await _client.get(
      Uri.parse('$_baseUrl$path'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/pdf'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _apiExceptionFromResponse(response);
    }
    final Uint8List bytes = response.bodyBytes;
    final safeFilename = (filename ?? 'campus-quest-portfolio').replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '-',
    );
    await FileSaver.instance.saveToDownloads(
      name: safeFilename,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? body,
    bool authenticated = true,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated) {
      final token = await readToken();
      if (token == null || token.isEmpty) {
        throw const ApiException('Please sign in again', statusCode: 401);
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('$_baseUrl$path');
    late final http.Response response;
    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _client.post(
          uri,
          headers: headers,
          body: jsonEncode(body),
        );
        break;
      case 'PATCH':
        response = await _client.patch(
          uri,
          headers: headers,
          body: jsonEncode(body),
        );
        break;
      case 'DELETE':
        response = await _client.delete(uri, headers: headers);
        break;
      default:
        throw ArgumentError.value(method, 'method', 'Unsupported HTTP method');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _apiExceptionFromResponse(response);
    }
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  ApiException _apiExceptionFromResponse(http.Response response) {
    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiException(
        payload['message'] as String? ?? 'The request could not be completed',
        statusCode: response.statusCode,
      );
    } on FormatException {
      return ApiException(
        'The request could not be completed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on TypeError {
      return ApiException(
        'The request could not be completed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
  }
}
