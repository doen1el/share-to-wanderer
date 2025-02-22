import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePageViewModel extends ChangeNotifier {
  var logger = Logger();

  Future<void> setDomain(String domain) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    logger.i('Setting domain to $domain');
    await prefs.setString('domain', domain);
  }

  Future<void> setUsername(String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    logger.i('Setting username to $username');
    await prefs.setString('username', username);
  }

  Future<void> setPassword(String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    logger.i('Setting password to $password');
    await prefs.setString('password', password);
  }

  Future<void> setUseHttps(bool useHttps) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    logger.i('Setting useHttps to $useHttps');
    await prefs.setBool('useHttps', useHttps);
  }

  Future<bool> getUseHttps() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('useHttps') ?? false;
  }

  Future<String> getDomain() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('domain') ?? '';
  }

  Future<String> getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? '';
  }

  Future<String> getPassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('password') ?? '';
  }

  // LOGIN:
  //   curl --header "Content-Type: application/json" --request POST \
  // --cookie-jar ./wanderer-credentials \
  // --data '{"username":"MyUser","password":"mysecretpassword"}' \
  // http://localhost:3000/api/v1/auth/login

  // UPLOAD GPX:
  //   curl --location --request PUT 'http://localhost:3000/api/v1/trail/upload' \
  // --header 'Content-Type: application/gpx+xml' \
  // --cookie './wanderer-credentials' \
  // --data-binary '@my_trail.gpx'
}
