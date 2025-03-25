import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/config.dart' as utils;

class AuthService {
  final String baseUrl = '${utils.BASE_URL}';
  static const String _tokenKey = 'access_token';
  static const String _lastLoginKey = 'last_login';
  static const String _userEmailKey = 'user_email';

  // Login user and store token
  Future<bool> login(String email, String password) async {
    try {
      print('Attempting login for email: $email');
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        print('Login successful, token received: ${token.substring(0, 10)}...');
        
        // Save all user data
        final prefs = await SharedPreferences.getInstance();
        await Future.wait([
          prefs.setString(_tokenKey, token),
          prefs.setString(_lastLoginKey, DateTime.now().toIso8601String()),
          prefs.setString(_userEmailKey, email),
        ]);
        
        print('User data saved successfully');
        return true;
      }
      print('Login failed with status code: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Logout user and remove token
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_tokenKey),
        prefs.remove(_lastLoginKey),
        prefs.remove(_userEmailKey),
      ]);
      print('Logged out, all user data removed');
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final lastLogin = prefs.getString(_lastLoginKey);
      final userEmail = prefs.getString(_userEmailKey);
      
      print('Checking login status:');
      print('- Token found: ${token != null}');
      print('- Last login: $lastLogin');
      print('- User email: $userEmail');
      
      if (token == null || lastLogin == null || userEmail == null) {
        print('Missing required login data');
        await logout();
        return false;
      }

      // Verify token with backend
      final response = await http.get(
        Uri.parse('$baseUrl/verify_token'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      print('Token verification response: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Token verified successfully');
        return true;
      } else {
        print('Token verification failed');
        await logout();
        return false;
      }
    } catch (e) {
      print('Error checking login status: $e');
      await logout();
      return false;
    }
  }

  // Get stored token
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Save token
  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      print('Token saved successfully');
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  // Save last login timestamp
  Future<void> _saveLastLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
      print('Last login timestamp saved');
    } catch (e) {
      print('Error saving last login: $e');
    }
  }

  // Get last login timestamp
  Future<String?> _getLastLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastLoginKey);
    } catch (e) {
      print('Error getting last login: $e');
      return null;
    }
  }

  // Get token for API requests
  Future<String?> getAuthToken() async {
    return await _getToken();
  }

  // Get user email
  Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userEmailKey);
    } catch (e) {
      print('Error getting user email: $e');
      return null;
    }
  }
} 