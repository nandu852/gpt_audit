import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response.dart';
import '../models/user.dart';

class AuthService {
  static const String _baseUrl = 'http://192.168.29.36:8080';
  static const String _signInEndpoint = '/auth/signin';
  static const String _refreshEndpoint = '/auth/refresh';
  
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  
  AuthService._();
  
  User? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  
  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _currentUser != null && _accessToken != null && !isTokenExpired();
  
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }
  
  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
    _currentUser = user;
  }
  
  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
  }
  
  Future<bool> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_signInEndpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        
        await _saveTokens(authResponse.accessToken, authResponse.refreshToken);
        await _saveUser(authResponse.user);
        
        return true;
      } else {
        print('Sign in failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Sign in error: $e');
      return false;
    }
  }
  
  Future<void> signOut() async {
    await _clearTokens();
  }
  
  Future<bool> loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final refreshToken = prefs.getString('refresh_token');
      final userDataString = prefs.getString('user_data');
      
      if (accessToken != null && refreshToken != null && userDataString != null) {
        _accessToken = accessToken;
        _refreshToken = refreshToken;
        _currentUser = User.fromJson(jsonDecode(userDataString));
        return true;
      }
      return false;
    } catch (e) {
      print('Error loading stored auth: $e');
      await _clearTokens();
      return false;
    }
  }
  
  Future<bool> refreshToken() async {
    if (_refreshToken == null) {
      print('No refresh token available');
      return false;
    }
    
    try {
      print('🔄 Refreshing token...');
      final response = await http.post(
        Uri.parse('$_baseUrl$_refreshEndpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'refresh_token': _refreshToken,
        }),
      );
      
      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await _saveTokens(authResponse.accessToken, authResponse.refreshToken);
        print('✅ Token refreshed successfully');
        return true;
      } else {
        print('❌ Token refresh failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        await _clearTokens();
        return false;
      }
    } catch (e) {
      print('💥 Token refresh error: $e');
      await _clearTokens();
      return false;
    }
  }
  
  bool isTokenExpired() {
    if (_accessToken == null) return true;
    
    try {
      // Decode JWT token to check expiration
      final parts = _accessToken!.split('.');
      if (parts.length != 3) return true;
      
      final payload = parts[1];
      // Add padding if needed
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(resp);
      
      final exp = payloadMap['exp'] as int?;
      if (exp == null) return true;
      
      final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      
      // Consider token expired if it expires within the next 5 minutes
      return now.isAfter(expirationTime.subtract(const Duration(minutes: 5)));
    } catch (e) {
      print('Error checking token expiration: $e');
      return true;
    }
  }
  
  Future<Map<String, String>> getAuthHeaders() async {
    // Check if token is expired and refresh if needed
    if (isTokenExpired()) {
      print('🕐 Token expired, attempting refresh...');
      final refreshed = await refreshToken();
      if (!refreshed) {
        print('❌ Failed to refresh token');
        return {'Content-Type': 'application/json'};
      }
    }
    
    if (_accessToken == null) {
      return {'Content-Type': 'application/json'};
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_accessToken',
    };
  }
}
