// lib/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final _storage = const FlutterSecureStorage();
const _tokenKey = 'auth_token';
const _userKey = 'user_profile';
const _userBranchKey = 'user_branch';
const _userSectionKey = 'user_section';
const _userSemesterKey = 'user_semester';
const _userRoleKey = 'user_role';

/// API expectations used by this service:
/// - Create user (multipart): POST  /api/users/add
///   fields: name,email,password,dob,rollNo,branch,semester,section,role + file field 'profile'
///
/// - Edit user by email (multipart): PUT /api/users/edit
///   fields: email (required), plus any of name,password,dob,rollNo,branch,semester,section,role
///   and optional file field 'profile'
///
/// - Upload avatar by email: POST /api/user/upload-avatar
///   fields: email (required), profile (file)
///
/// If your backend uses different paths, update the endpoint strings below.
class ApiService {
  //static const String baseUrl = 'http://10.0.2.2:4000';
  static const String baseUrl = 'http://127.0.0.1:4000'; // change to match your environment

  // ---------------------------
  // Secure storage helpers
  // ---------------------------
  static Future<void> saveToken(String token) async => await _storage.write(key: _tokenKey, value: token);
  static Future<String?> readToken() async => await _storage.read(key: _tokenKey);
  static Future<void> deleteToken() async => await _storage.delete(key: _tokenKey);

  /// Save full user object as JSON string. Also store convenient fields separately.
  /// This will include the 'profile' object returned by server (if present).
  static Future<void> saveUserProfile(Map<String, dynamic> user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user));

    final branch = user['branch']?.toString();
    final section = user['section']?.toString();
    final semester = user['semester']?.toString();
    final role = user['role']?.toString();

    if (branch != null) await _storage.write(key: _userBranchKey, value: branch);
    if (section != null) await _storage.write(key: _userSectionKey, value: section);
    if (semester != null) await _storage.write(key: _userSemesterKey, value: semester);
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

  static Future<String?> readBranch() async => await _storage.read(key: _userBranchKey);
  static Future<String?> readSection() async => await _storage.read(key: _userSectionKey);
  static Future<String?> readSemester() async => await _storage.read(key: _userSemesterKey);
  static Future<String?> readRole() async => await _storage.read(key: _userRoleKey);

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final t = await readToken();
      if (t != null) headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  // ---------------------------
  // Existing endpoints (unchanged)
  // ---------------------------

  /// Login - store token and user profile if successful
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

  /// Forgot password
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
    required String dob, // formatted as YYYY-MM-DD
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/forgot-password');
    final body = jsonEncode({'email': email, 'dob': dob});
    final res = await http.post(url, headers: await _headers(), body: body);

    Map<String, dynamic> decoded;
    if (res.body.isNotEmpty) {
      final dynamic tmp = jsonDecode(res.body);
      if (tmp is Map) decoded = Map<String, dynamic>.from(tmp);
      else decoded = <String, dynamic>{'data': tmp};
    } else {
      decoded = <String, dynamic>{};
    }

    if (res.statusCode == 200 || res.statusCode == 201) {
      return decoded;
    } else {
      String err;
      if (decoded.containsKey('error') && decoded['error'] is String) {
        err = decoded['error'] as String;
      } else if (decoded.containsKey('message') && decoded['message'] is String) {
        err = decoded['message'] as String;
      } else {
        err = 'Forgot password failed (${res.statusCode})';
      }
      throw Exception(err);
    }
  }

  /// Get timetable for logged-in user
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

  /// Search timetable
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

  // ---------------------------
  // NEW: user creation / edit / avatar upload (email-based)
  // ---------------------------

  /// Create user (multipart) - REQUIRES profile image
  /// Fields: name, email, password, dob, rollNo, branch, semester, section, role, profile (file)
  static Future<Map<String, dynamic>> createUserWithProfile({
    required String name,
    required String email,
    required String password,
    required DateTime dob,
    required String profilePath,
    required String role,
    required String rollNo,
    required int semester,
    required String section,
    required String branch,
  }) async {
    // Validate file exists
    final file = File(profilePath);
    if (!file.existsSync()) throw Exception('Profile file does not exist: $profilePath');

    final uri = Uri.parse('$baseUrl/api/users/add');
    final request = http.MultipartRequest('POST', uri);

    request.fields['name'] = name;
    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['dob'] = dob.toIso8601String();
    request.fields['role'] = role;
    request.fields['rollNo'] = rollNo;
    request.fields['semester'] = semester.toString();
    request.fields['section'] = section;
    request.fields['branch'] = branch;

    // attach file under field name 'profile'
    final multipartFile = await http.MultipartFile.fromPath('profile', profilePath);
    request.files.add(multipartFile);

    // attach auth header if present
    final headers = await _headers(auth: true);
    request.headers.addAll(headers);

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    final body = res.body.isNotEmpty ? jsonDecode(res.body) as Map<String, dynamic> : <String, dynamic>{};

    if (res.statusCode == 200 || res.statusCode == 201) {
      // optionally save user profile if returned
      if (body['user'] != null && body['user'] is Map) {
        await saveUserProfile(body['user'] as Map<String, dynamic>);
      }
      return body;
    } else {
      final message = (body is Map && body.containsKey('message')) ? body['message'] : res.body;
      throw Exception('Create user failed (${res.statusCode}): $message');
    }
  }

  /// Update user by email (multipart). Backend must support PUT /api/users/edit and accept 'email' field.
  /// Provide whichever fields you want to update. profilePath optional.
  static Future<Map<String, dynamic>> updateUserByEmailWithProfile({
    required String email,
    String? name,
    String? password,
    DateTime? dob,
    String? profilePath,
    String? role,
    String? rollNo,
    int? semester,
    String? section,
    String? branch,
  }) async {
    final uri = Uri.parse('$baseUrl/api/users/edit'); // email-based edit endpoint (backend must implement)
    final request = http.MultipartRequest('PUT', uri);

    request.fields['email'] = email; // required to identify the user on server-side

    if (name != null) request.fields['name'] = name;
    if (password != null) request.fields['password'] = password;
    if (dob != null) request.fields['dob'] = dob.toIso8601String();
    if (role != null) request.fields['role'] = role;
    if (rollNo != null) request.fields['rollNo'] = rollNo;
    if (semester != null) request.fields['semester'] = semester.toString();
    if (section != null) request.fields['section'] = section;
    if (branch != null) request.fields['branch'] = branch;

    if (profilePath != null) {
      final file = File(profilePath);
      if (!file.existsSync()) throw Exception('Profile file does not exist: $profilePath');
      final multipartFile = await http.MultipartFile.fromPath('profile', profilePath);
      request.files.add(multipartFile);
    }

    final headers = await _headers(auth: true);
    request.headers.addAll(headers);

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final body = res.body.isNotEmpty ? jsonDecode(res.body) as Map<String, dynamic> : <String, dynamic>{};

    if (res.statusCode == 200) {
      // if server returns updated user, update stored profile
      if (body['user'] != null && body['user'] is Map) {
        await saveUserProfile(body['user'] as Map<String, dynamic>);
      }
      return body;
    } else {
      final message = (body is Map && body.containsKey('message')) ? body['message'] : res.body;
      throw Exception('Update failed (${res.statusCode}): $message');
    }
  }

  /// Upload avatar by email (email-only route)
  static Future<Map<String, dynamic>> uploadAvatarByEmail({
    required String email,
    required String profilePath,
  }) async {
    final file = File(profilePath);
    if (!file.existsSync()) throw Exception('Profile file does not exist: $profilePath');

    final uri = Uri.parse('$baseUrl/api/user/upload-avatar');
    final request = http.MultipartRequest('POST', uri);

    request.fields['email'] = email;
    final multipartFile = await http.MultipartFile.fromPath('profile', profilePath);
    request.files.add(multipartFile);

    final headers = await _headers(auth: true);
    request.headers.addAll(headers);

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final body = res.body.isNotEmpty ? jsonDecode(res.body) as Map<String, dynamic> : <String, dynamic>{};

    if (res.statusCode == 200) {
      // backend returns updated user under `data` — do not overwrite storage unless desired
      // if you want to update stored profile automatically, uncomment below:
      // if (body['data'] != null && body['data']['profile'] != null) { ... }
      return body;
    } else {
      final message = (body is Map && body.containsKey('message')) ? body['message'] : res.body;
      throw Exception('Upload avatar failed (${res.statusCode}): $message');
    }
  }
}
