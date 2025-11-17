// lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final _storage = FlutterSecureStorage();
const _tokenKey = 'auth_token';
const _userKey = 'user_profile';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:4000'; // set per environment

  // Save token securely
  static Future<void> saveToken(String token) async => await _storage.write(key: _tokenKey, value: token);
  static Future<String?> readToken() async => await _storage.read(key: _tokenKey);
  static Future<void> deleteToken() async => await _storage.delete(key: _tokenKey);

  // Save / read user profile as JSON string
  static Future<void> saveUserProfile(Map<String, dynamic> user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user));
  }
  static Future<Map<String, dynamic>?> readUserProfile() async {
    final s = await _storage.read(key: _userKey);
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }
  static Future<void> deleteUserProfile() async {
    await _storage.delete(key: _userKey);
  }

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final t = await readToken();
      if (t != null) headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  // Login - store token and user profile if successful
  static Future<Map> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final res = await http.post(url,
        headers: await _headers(),
        body: jsonEncode({'email': email, 'password': password}));
    final body = res.body.isNotEmpty ? jsonDecode(res.body) as Map<String, dynamic> : {};
    if (res.statusCode == 200) {
      if (body['token'] != null) await saveToken(body['token']);
      if (body['user'] != null) await saveUserProfile(body['user'] as Map<String, dynamic>);
      return body;
    } else {
      throw Exception(body['error'] ?? 'Login failed (${res.statusCode})');
    }
  }

// ... other methods (getMyTimetable, searchTimetable) remain unchanged

// Get timetable for logged-in user
  static Future<Map<String, dynamic>> getMyTimetable() async {
    final url = Uri.parse('$baseUrl/api/timetable/me');
    final res = await http.get(url, headers: await _headers(auth: true));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      throw Exception(body['error'] ?? 'Failed to fetch timetable (${res.statusCode})');
    }
  }

  // Search timetable by params
  static Future<Map<String, dynamic>> searchTimetable({
    required String semester,
    required String branch,
    required String section,
  }) async {
    final q = Uri(queryParameters: {'semester': semester, 'branch': branch, 'section': section});
    final url = Uri.parse('$baseUrl/api/timetable/search${q.toString()}');
    final res = await http.get(url, headers: await _headers(auth: true));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      throw Exception(body['error'] ?? 'Search failed (${res.statusCode})');
    }
  }
}
