// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // CHANGE this depending on environment:
  // Android emulator -> 10.0.2.2
  // iOS simulator -> localhost
  // Physical device -> your machine LAN IP like http://192.168.x.x:4000
  final String baseUrl = 'http://10.0.2.2:4000';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    if (res.statusCode == 200) {
      final token = body['token'];
      if (token != null) await _storage.write(key: _tokenKey, value: token);
      return {'ok': true, 'user': body['user'], 'token': token};
    } else {
      return {'ok': false, 'error': body['error'] ?? body};
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);
}
