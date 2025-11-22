// lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final _storage = const FlutterSecureStorage();
const _tokenKey = 'auth_token';
const _userKey = 'user_profile';
const _userBranchKey = 'user_branch';
const _userSectionKey = 'user_section';
const _userSemesterKey = 'user_semester';
const _userRoleKey = 'user_role';

class ApiService {
  static const String baseUrl = 'http://localhost:4000'; // set per environment
  //static const String baseUrl = 'http://10.0.2.2:4000';

  // Save token securely
  static Future<void> saveToken(String token) async =>
      await _storage.write(key: _tokenKey, value: token);
  static Future<String?> readToken() async =>
      await _storage.read(key: _tokenKey);
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Save / read user profile as JSON string (and also save fields individually)
  static Future<void> saveUserProfile(Map<String, dynamic> user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user));

    // save common fields individually for ease of access
    final branch = user['branch']?.toString();
    final section = user['section']?.toString();
    final semester = user['semester']?.toString();
    final role = user['role']?.toString();

    if (branch != null)
      await _storage.write(key: _userBranchKey, value: branch);
    if (section != null)
      await _storage.write(key: _userSectionKey, value: section);
    if (semester != null)
      await _storage.write(key: _userSemesterKey, value: semester);
    if (role != null) await _storage.write(key: _userRoleKey, value: role);
  }

  static Future<Map<String, dynamic>?> readUserProfile() async {
    final s = await _storage.read(key: _userKey);
    if (s == null) return null;
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteUserProfile() async {
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _userBranchKey);
    await _storage.delete(key: _userSectionKey);
    await _storage.delete(key: _userSemesterKey);
    await _storage.delete(key: _userRoleKey);
  }

  // Convenience getters for separate fields
  static Future<String?> readBranch() async =>
      await _storage.read(key: _userBranchKey);
  static Future<String?> readSection() async =>
      await _storage.read(key: _userSectionKey);
  static Future<String?> readSemester() async =>
      await _storage.read(key: _userSemesterKey);
  static Future<String?> readRole() async =>
      await _storage.read(key: _userRoleKey);

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
    final res = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = res.body.isNotEmpty
        ? jsonDecode(res.body) as Map<String, dynamic>
        : {};
    if (res.statusCode == 200) {
      if (body['token'] != null) await saveToken(body['token']);
      if (body['user'] != null)
        await saveUserProfile(body['user'] as Map<String, dynamic>);
      return body;
    } else {
      throw Exception(body['error'] ?? 'Login failed (${res.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
    required String dob,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/forgot-password');
    final body = jsonEncode({'email': email, 'dob': dob});
    final res = await http.post(url, headers: await _headers(), body: body);

    Map<String, dynamic> decoded;
    if (res.body.isNotEmpty) {
      final dynamic tmp = jsonDecode(res.body);
      if (tmp is Map) {
        decoded = Map<String, dynamic>.from(tmp);
      } else {
        decoded = <String, dynamic>{'data': tmp};
      }
    } else {
      decoded = <String, dynamic>{};
    }

    if (res.statusCode == 200 || res.statusCode == 201) {
      return decoded;
    } else {
      String err;
      if (decoded.containsKey('error') && decoded['error'] is String) {
        err = decoded['error'] as String;
      } else if (decoded.containsKey('message') &&
          decoded['message'] is String) {
        err = decoded['message'] as String;
      } else {
        err = 'Forgot password failed (${res.statusCode})';
      }
      throw Exception(err);
    }
  }

  // Get timetable for logged-in user
  static Future<Map<String, dynamic>> getMyTimetable() async {
    final url = Uri.parse('$baseUrl/api/timetable/me');
    final res = await http.get(url, headers: await _headers(auth: true));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      throw Exception(
        body['error'] ?? 'Failed to fetch timetable (${res.statusCode})',
      );
    }
  }

  // Search timetable by params
  static Future<Map<String, dynamic>> searchTimetable({
    required String semester,
    required String branch,
    required String section,
  }) async {
    final q = Uri(
      queryParameters: {
        'semester': semester,
        'branch': branch,
        'section': section,
      },
    );
    final url = Uri.parse('$baseUrl/api/timetable/search${q.toString()}');
    final res = await http.get(url, headers: await _headers(auth: true));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      throw Exception(body['error'] ?? 'Search failed (${res.statusCode})');
    }
  }

  // ============ EVENT APIs ============

  // Get all events
  static Future<List<Map<String, dynamic>>> getAllEvents() async {
    final url = Uri.parse('$baseUrl/api/events');
    final res = await http.get(url, headers: await _headers(auth: true));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body['events'] != null) {
        return List<Map<String, dynamic>>.from(body['events']);
      }
      return [];
    } else {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      throw Exception(
        body['error'] ?? 'Failed to fetch events (${res.statusCode})',
      );
    }
  }

  // Create new event (admin/teacher only)
  static Future<Map<String, dynamic>> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String imageUrl,
    required List<String> regulations,
  }) async {
    final url = Uri.parse('$baseUrl/api/events');
    final res = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode({
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'imageUrl': imageUrl,
        'regulations': regulations,
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      throw Exception(
        body['error'] ?? 'Failed to create event (${res.statusCode})',
      );
    }
  }

  // Update event (admin/teacher only)
  static Future<Map<String, dynamic>> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required DateTime date,
    required String imageUrl,
    required List<String> regulations,
  }) async {
    final url = Uri.parse('$baseUrl/api/events/$eventId');
    final res = await http.put(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode({
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'imageUrl': imageUrl,
        'regulations': regulations,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      throw Exception(
        body['error'] ?? 'Failed to update event (${res.statusCode})',
      );
    }
  }

  // Delete event (admin only)
  static Future<void> deleteEvent(String eventId) async {
    final url = Uri.parse('$baseUrl/api/events/$eventId');
    final res = await http.delete(url, headers: await _headers(auth: true));

    if (res.statusCode != 200 && res.statusCode != 204) {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      throw Exception(
        body['error'] ?? 'Failed to delete event (${res.statusCode})',
      );
    }
  }

  // Register for an event
  static Future<Map<String, dynamic>> registerForEvent({
    required String eventId,
    required String studentName,
    required String studentEmail,
    required String rollNo,
    required String branch,
    required String section,
    String? phoneNumber,
  }) async {
    final url = Uri.parse('$baseUrl/api/events/$eventId/register');
    final res = await http.post(
      url,
      headers: await _headers(auth: true),
      body: jsonEncode({
        'studentName': studentName,
        'studentEmail': studentEmail,
        'rollNo': rollNo,
        'branch': branch,
        'section': section,
        'phoneNumber': phoneNumber,
      }),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      throw Exception(
        body['error'] ?? 'Failed to register for event (${res.statusCode})',
      );
    }
  }

  // Get registrations for an event (admin/teacher only)
  static Future<List<Map<String, dynamic>>> getEventRegistrations(
    String eventId,
  ) async {
    final url = Uri.parse('$baseUrl/api/events/$eventId/registrations');
    final res = await http.get(url, headers: await _headers(auth: true));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body['registrations'] != null) {
        return List<Map<String, dynamic>>.from(body['registrations']);
      }
      return [];
    } else {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      throw Exception(
        body['error'] ?? 'Failed to fetch registrations (${res.statusCode})',
      );
    }
  }
}
