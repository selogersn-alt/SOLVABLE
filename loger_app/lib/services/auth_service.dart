import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = 'https://logersenegal.com/api/users';
  final _storage = const FlutterSecureStorage();
  
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/'),
        body: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storage.write(key: 'access_token', value: data['access']);
        await _storage.write(key: 'refresh_token', value: data['refresh']);
        
        // Fetch profile immediately after login
        return await fetchProfile();
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> fetchProfile() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _currentUser = AppUser.fromJson(json.decode(response.body));
        return true;
      } else if (response.statusCode == 401) {
        // Token expired, should try to refresh (simplified for now)
        await logout();
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    _currentUser = null;
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null && _currentUser == null) {
      return await fetchProfile();
    }
    return token != null;
  }
}
