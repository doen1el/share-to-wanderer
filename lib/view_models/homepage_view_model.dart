import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class HomePageViewModel extends ChangeNotifier {
  var logger = Logger();

  /// Get the SharedPreferences instance
  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  /// Set a string value in SharedPreferences
  ///
  /// Parameters:
  ///
  /// - `key`: The key to set
  /// - `value`: The value to set
  Future<void> _setString(String key, String value) async {
    final prefs = await _getPrefs();
    logger.i('Setting $key to $value');
    await prefs.setString(key, value);
    notifyListeners();
  }

  /// Set a boolean value in SharedPreferences
  ///
  /// Parameters:
  ///
  /// - `key`: The key to set
  /// - `value`: The value to set
  Future<void> _setBool(String key, bool value) async {
    final prefs = await _getPrefs();
    logger.i('Setting $key to $value');
    await prefs.setBool(key, value);
    notifyListeners();
  }

  /// Get a string value from SharedPreferences
  ///
  /// Parameters:
  ///
  /// - `key`: The key to get
  Future<String> _getString(String key, {String defaultValue = ''}) async {
    final prefs = await _getPrefs();
    return prefs.getString(key) ?? defaultValue;
  }

  /// Get a boolean value from SharedPreferences
  ///
  /// Parameters:
  ///
  /// - `key`: The key to get
  Future<bool> _getBool(String key, {bool defaultValue = false}) async {
    final prefs = await _getPrefs();
    return prefs.getBool(key) ?? defaultValue;
  }

  /// Set the domain in SharedPreferences
  ///
  /// Parameters:
  ///
  /// - `domain`: The domain to set
  Future<void> setDomain(String domain) async {
    await _setString('domain', domain);
  }

  /// Set the username in SharedPreferences
  ///
  /// Parameters:
  ///
  /// - `username`: The username to set
  Future<void> setUsername(String username) async {
    await _setString('username', username);
  }

  /// Set the password in SharedPreferences
  ///
  /// Parameters:
  ///
  /// - `password`: The password to set
  Future<void> setPassword(String password) async {
    await _setString('password', password);
  }

  /// Set whether to use HTTPS in SharedPreferences
  ///
  /// Parameters:
  ///
  /// - `useHttps`: Whether to use HTTPS
  Future<void> setUseHttps(bool useHttps) async {
    await _setBool('useHttps', useHttps);
  }

  /// Get whether to use HTTPS from SharedPreferences
  Future<bool> getUseHttps() async {
    return await _getBool('useHttps');
  }

  /// Get the domain from SharedPreferences
  Future<String> getDomain() async {
    return await _getString('domain');
  }

  /// Get the username from SharedPreferences
  Future<String> getUsername() async {
    return await _getString('username');
  }

  /// Get the password from SharedPreferences
  Future<String> getPassword() async {
    return await _getString('password');
  }

  /// Test the connection to the Wanderer instance
  Future<bool> testConnection() async {
    final domain = await getDomain();
    final username = await getUsername();
    final password = await getPassword();

    if (domain.isEmpty || username.isEmpty || password.isEmpty) {
      logger.e('Missing credentials');
      return false;
    }

    final protocol = await getUseHttps() ? 'https' : 'http';
    final url = Uri.parse('$protocol://$domain/api/v1/auth/login');
    logger.i('Logging in to $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: '{"username":"$username","password":"$password"}',
      );

      if (response.statusCode == 200) {
        logger.i('Login successful');
        return true;
      } else {
        logger.e('Login failed: ${response.body}');
        return false;
      }
    } catch (e) {
      logger.e('Error during connection test: $e');
      return false;
    }
  }
}
