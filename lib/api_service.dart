import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'timetable_model.dart'; // Ensure this matches your file name

final _storage = const FlutterSecureStorage();
const _tokenKey = 'auth_token';
const _userKey = 'user_profile';
const _userBranchKey = 'user_branch';
const _userSectionKey = 'user_section';
const _userSemesterKey = 'user_semester';
const _userRoleKey = 'user_role';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for iOS Simulator/Web
  static const String baseUrl = 'http://127.0.0.1:4000';

  // ===========================================================================
  // SECTION 1: HEADERS & TOKENS (Infrastructure)
  // ===========================================================================

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final t = await readToken();
      if (t != null) headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  static Future<void> saveToken(String token) async => await _storage.write(key: _tokenKey, value: token);
  static Future<String?> readToken() async => await _storage.read(key: _tokenKey);
  static Future<void> deleteToken() async => await _storage.delete(key: _tokenKey);

  static Future<void> saveUserProfile(Map<String, dynamic> user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user));
    if (user['branch'] != null) await _storage.write(key: _userBranchKey, value: user['branch'].toString());
    if (user['section'] != null) await _storage.write(key: _userSectionKey, value: user['section'].toString());
    if (user['semester'] != null) await _storage.write(key: _userSemesterKey, value: user['semester'].toString());
    if (user['role'] != null) await _storage.write(key: _userRoleKey, value: user['role'].toString());
  }

  static Future<Map<String, dynamic>?> readUserProfile() async {
    final s = await _storage.read(key: _userKey);
    return s == null ? null : jsonDecode(s) as Map<String, dynamic>;
  }

  static Future<void> deleteUserProfile() async {
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _userBranchKey);
    await _storage.delete(key: _userSectionKey);
    await _storage.delete(key: _userSemesterKey);
    await _storage.delete(key: _userRoleKey);
  }

  // Helper getters for current user info
  static Future<String?> readBranch() async => await _storage.read(key: _userBranchKey);
  static Future<String?> readSection() async => await _storage.read(key: _userSectionKey);
  static Future<String?> readSemester() async => await _storage.read(key: _userSemesterKey);
  static Future<String?> readRole() async => await _storage.read(key: _userRoleKey);


  // ===========================================================================
  // SECTION 2: COURSES (New)
  // ===========================================================================

  static Future<void> addCourse(Map<String, dynamic> courseData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/courses'), // Updated path to include /api prefix if your app.js uses it
      headers: await _headers(auth: true),
      body: jsonEncode(courseData),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add course: ${response.body}');
    }
  }

  static Future<List<Course>> getCourses(String branch, String semester, String section) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/courses?branch=$branch&semester=$semester&section=$section'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((course) => Course.fromJson(course)).toList();
    } else {
      throw Exception('Failed to load courses');
    }
  }


  // ===========================================================================
  // SECTION 3: TIMETABLE - ADMIN & SEARCH (New)
  // ===========================================================================

  // Create Timetable (Admin)
  static Future<void> addTimetable(Map<String, dynamic> timetableData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/timetable'),
      headers: await _headers(auth: true),
      body: jsonEncode(timetableData),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body)['message'] ?? 'Unknown error';
      throw Exception(error);
    }
  }

  // Update Timetable (Admin)
  static Future<void> updateTimetable(Map<String, dynamic> timetableData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/timetable'),
      headers: await _headers(auth: true),
      body: jsonEncode(timetableData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update timetable: ${response.body}');
    }
  }

  // Get Specific Timetable (Admin Edit / Search)
  static Future<Timetable> getTimetable(String branch, String semester, String section) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/timetable?branch=$branch&semester=$semester&section=$section'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Timetable.fromJson(data['timetable']);
    } else if (response.statusCode == 404) {
      throw Exception("Not Found");
    } else {
      throw Exception('Failed to load timetable');
    }
  }


  // ===========================================================================
  // SECTION 4: TIMETABLE - USERS (Student, Teacher, ClassRep)
  // ===========================================================================

  // Get My Timetable (Student/ClassRep - Auto Fetch)
  static Future<Timetable> getMyTimetable() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/timetable/me'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Timetable.fromJson(data['timetable']);
    } else {
      throw Exception('No timetable found for your class.');
    }
  }

  // Get Teacher Timetable (Personalized View)
  static Future<List<TimetableDay>> getTeacherTimetable() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/timetable/teacher'),
      headers: await _headers(auth: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      var list = data['grid'] as List;
      return list.map((i) => TimetableDay.fromJson(i)).toList();
    } else {
      throw Exception('Failed to load teacher schedule');
    }
  }

  // Update Single Slot (ClassRep/Teacher - Cancel/RoomChange)
  static Future<void> updateSlot({
    required String semester,
    required String branch,
    required String section,
    required String dayName,
    required int slotIndex,
    bool? isCancelled,
    String? newRoom,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/timetable/slot'),
      headers: await _headers(auth: true),
      body: jsonEncode({
        'semester': semester,
        'branch': branch,
        'section': section,
        'dayName': dayName,
        'slotIndex': slotIndex,
        if (isCancelled != null) 'isCancelled': isCancelled,
        if (newRoom != null) 'newRoom': newRoom,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update slot');
    }
  }


  // ===========================================================================
  // SECTION 5: AUTHENTICATION (Existing)
  // ===========================================================================

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

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
    required String dob,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/forgot-password');
    final body = jsonEncode({'email': email, 'dob': dob});
    final res = await http.post(url, headers: await _headers(), body: body);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    } else {
      final decoded = jsonDecode(res.body);
      throw Exception(decoded['error'] ?? 'Forgot password failed');
    }
  }


  // ===========================================================================
  // SECTION 6: USER MANAGEMENT (Existing - Create/Edit/Upload)
  // ===========================================================================

  static Future<Map<String, dynamic>> createUserWithProfile({
    required String name,
    required String email,
    required String password,
    required DateTime dob,
    required String profilePath,
    required String role,
    required String rollNo,
    required String semester, // Note: Changed to String to match "S5"
    required String section,
    required String branch,
  }) async {
    final file = File(profilePath);
    if (!file.existsSync()) throw Exception('Profile file does not exist: $profilePath');

    final uri = Uri.parse('$baseUrl/api/auth/register'); // Typically register is in auth routes, check your backend
    // OR if you use the admin add route: '$baseUrl/api/users/add' 
    // Based on your previous files, register was in /api/auth/register. 
    // I will default to the one you had in comments:
    // "POST /api/users/add" based on your comments.
    // Let's stick to the path you used in your provided code:
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/auth/register'));

    request.fields['name'] = name;
    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['dob'] = dob.toIso8601String();
    request.fields['role'] = role;
    request.fields['rollNo'] = rollNo;
    request.fields['semester'] = semester;
    request.fields['section'] = section;
    request.fields['branch'] = branch;

    final multipartFile = await http.MultipartFile.fromPath('profile', profilePath); // Changed field name to 'profile' per backend
    request.files.add(multipartFile);

    // No auth headers for registration usually? 
    // If this is "Admin adds user", include auth. If "Public Register", do not.
    // Your comment said "Create user (multipart): POST /api/users/add", usually admin only.
    // But standard register is public. I will check your backend... 
    // Your backend routes/auth.js has /register. It does NOT use authMiddleware.
    // So we do NOT add headers.
    // request.headers.addAll(await _headers(auth: true)); 

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200 || res.statusCode == 201) {
      final body = jsonDecode(res.body);
      return body;
    } else {
      throw Exception('Create user failed: ${res.body}');
    }
  }

  static Future<Map<String, dynamic>> updateUserByEmailWithProfile({
    required String email,
    String? name,
    String? password,
    DateTime? dob,
    String? profilePath,
    String? role,
    String? rollNo,
    String? semester,
    String? section,
    String? branch,
  }) async {
    // Adjust endpoint to your backend. 
    // If you use the `editUser.js` logic, you might need a route for it.
    // Assuming standard user route:
    final uri = Uri.parse('$baseUrl/api/user/edit');
    final request = http.MultipartRequest('PUT', uri);

    request.fields['email'] = email;
    if (name != null) request.fields['name'] = name;
    if (password != null) request.fields['password'] = password;
    if (dob != null) request.fields['dob'] = dob.toIso8601String();
    if (role != null) request.fields['role'] = role;
    if (rollNo != null) request.fields['rollNo'] = rollNo;
    if (semester != null) request.fields['semester'] = semester;
    if (section != null) request.fields['section'] = section;
    if (branch != null) request.fields['branch'] = branch;

    if (profilePath != null) {
      final multipartFile = await http.MultipartFile.fromPath('profile', profilePath);
      request.files.add(multipartFile);
    }

    final headers = await _headers(auth: true);
    request.headers.addAll(headers);

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body['user'] != null) await saveUserProfile(body['user']);
      return body;
    } else {
      throw Exception('Update failed: ${res.body}');
    }
  }

  static Future<Map<String, dynamic>> uploadAvatarByEmail({
    required String email,
    required String profilePath,
  }) async {
    final uri = Uri.parse('$baseUrl/api/user/upload-avatar');
    final request = http.MultipartRequest('POST', uri);

    request.fields['email'] = email;
    final multipartFile = await http.MultipartFile.fromPath('profile', profilePath);
    request.files.add(multipartFile);

    request.headers.addAll(await _headers(auth: true));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Upload avatar failed: ${res.body}');
    }
  }
}