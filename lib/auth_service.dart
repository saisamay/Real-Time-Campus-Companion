// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // Android emulator → backend
  final String baseUrl = 'http://localhost:4000';
  //final String baseUrl = 'http://10.0.2.2:4000';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  /// --- LOGIN ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data =
    response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200) {
      final token = data['token'];
      final user = data['user'];

      // Save token + user profile locally
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userKey, value: jsonEncode(user));

      return {
        'ok': true,
        'token': token,
        'user': user,
      };
    }

    // 400 / 401 / 500 etc
    return {
      'ok': false,
      'error': data['error'] ?? 'Unknown error'
    };
  }

  /// --- LOGOUT ---
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  /// --- READ TOKEN ---
  Future<String?> getToken() => _storage.read(key: _tokenKey);

  /// --- READ USER PROFILE ---
  Future<Map<String, dynamic>?> getUser() async {
    final jsonString = await _storage.read(key: _userKey);
    if (jsonString == null) return null;
    return jsonDecode(jsonString);
  }
}
