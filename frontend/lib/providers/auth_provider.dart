// lib/providers/auth_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/user.dart';
import '../utils/http_exception.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  User? _user;
  Timer? _authTimer;
  bool _isLoading = true;

  bool get isAuth {
    return _token != null;
  }
  

  String? get token {
    return _token;
  }

  User? get user {
    return _user;
  }

User? get currentUser => _user;

  bool get isLoading {
    return _isLoading;
  }

  AuthProvider() {
    autoLogin();
  }

  Future<void> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    final extractedUserData = json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    final expiryDate = DateTime.parse(extractedUserData['expiryDate']);

    if (expiryDate.isBefore(DateTime.now())) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _token = extractedUserData['token'];
    _user = User.fromJson(extractedUserData['user']);
    
    final expiryDuration = expiryDate.difference(DateTime.now());
    _autoLogout(expiryDuration.inSeconds);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final url = '${dotenv.env['API_URL']}/login';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      print(response.body);  // Add this line to log the response body

      final responseData = json.decode(response.body);
      
      if (response.statusCode >= 400) {
        throw HttpException(responseData['message'] ?? 'Authentication failed');
      }

      _token = responseData['access_token'];
      _user = User.fromJson(responseData['user']);
      
      // Set auto logout timer (24 hours)
      const expiryDuration = Duration(hours: 24);
      _autoLogout(expiryDuration.inSeconds);
      
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': _token,
        'user': responseData['user'],
        'expiryDate': DateTime.now().add(expiryDuration).toIso8601String(),
      });
      prefs.setString('userData', userData);
      
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password, String role, String direction) async {
    final url = '${dotenv.env['API_URL']}/register';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'direction': direction,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode >= 400) {
        throw HttpException(responseData['message'] ?? 'Registration failed');
      }

      _token = responseData['access_token'];
      _user = User.fromJson(responseData['data']);
      
      // Set auto logout timer (24 hours)
      const expiryDuration = Duration(hours: 24);
      _autoLogout(expiryDuration.inSeconds);
      
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': _token,
        'user': responseData['data'],
        'expiryDate': DateTime.now().add(expiryDuration).toIso8601String(),
      });
      prefs.setString('userData', userData);
      
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> logout() async {
    final url = '${dotenv.env['API_URL']}/logout';
    
    try {
      await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
    } catch (error) {
      // Ignore errors on logout
    }

    _token = null;
    _user = null;
    if (_authTimer != null) {
      _authTimer!.cancel();
      _authTimer = null;
    }
    
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userData');
    
    notifyListeners();
  }

  void _autoLogout(int seconds) {
    if (_authTimer != null) {
      _authTimer!.cancel();
    }
    _authTimer = Timer(Duration(seconds: seconds), logout);
  }

  Future<void> updateProfile(String name, String email, {String? currentPassword, String? newPassword}) async {
    final url = '${dotenv.env['API_URL']}/profile';
    
    try {
      final data = {
        'name': name,
        'email': email,
      };
      
      if (currentPassword != null && newPassword != null) {
        data['current_password'] = currentPassword;
        data['new_password'] = newPassword;
      }
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode(data),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode >= 400) {
        throw HttpException(responseData['message'] ?? 'Profile update failed');
      }

      _user = User.fromJson(responseData);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }
}
