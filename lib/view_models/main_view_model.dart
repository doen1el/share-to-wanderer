import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MainViewModel extends ChangeNotifier {
  var logger = Logger();
  late StreamSubscription _intentSub;
  final _sharedFiles = <SharedMediaFile>[];

  void disposeSharingIntent() {
    logger.i('Disposing sharing intent');
    _intentSub.cancel();
  }

  void initialiseSharingInten() {
    logger.i('Initialising sharing intent');
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (value) {
        _sharedFiles.clear();
        _sharedFiles.addAll(value);
        logger.i(_sharedFiles.map((f) => f.toMap()).toString());
        notifyListeners();

        // Upload GPX files automatically
        for (var file in _sharedFiles) {
          if (file.path.endsWith('.gpx')) {
            uploadGpx(file.path);
          } else {
            logger.i('Ignoring non-GPX file: ${file.path}');
            Fluttertoast.showToast(
              msg: 'File is not a GPX file',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
          }
        }
      },
      onError: (err) {
        logger.e("getIntentDataStream error: $err");
      },
    );

    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      _sharedFiles.clear();
      _sharedFiles.addAll(value);
      logger.i(_sharedFiles.map((f) => f.toMap()).toString());
      notifyListeners();

      // Upload GPX files automatically
      for (var file in _sharedFiles) {
        if (file.path.endsWith('.gpx')) {
          uploadGpx(file.path);
        } else {
          logger.i('Ignoring non-GPX file: ${file.path}');
          Fluttertoast.showToast(
            msg: 'File is not a GPX file',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      }

      ReceiveSharingIntent.instance.reset();
    });
  }

  Future<Cookie> login(
    String domain,
    String username,
    String password,
    String protocol,
  ) async {
    final url = Uri.parse('$protocol://$domain/api/v1/auth/login');
    logger.i('Logging in to $url');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: '{"username":"$username","password":"$password"}',
    );

    if (response.statusCode == 200) {
      logger.i('Login successful');
      // Extract cookies from response
      final cookies = response.headers['set-cookie'];
      if (cookies != null) {
        final cookie = Cookie.fromSetCookieValue(cookies);
        return cookie;
      } else {
        throw Exception('No cookies found in response');
      }
    } else {
      logger.e('Login failed: ${response.body}');
      throw Exception('Login failed');
    }
  }

  Future<void> uploadGpx(String filePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String domain = prefs.getString('domain') ?? '';
    String username = prefs.getString('username') ?? '';
    String password = prefs.getString('password') ?? '';
    bool useHttps = prefs.getBool('useHttps') ?? false;

    if (domain.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        filePath.isEmpty) {
      logger.e('Missing credentials');
      return;
    }

    try {
      // Perform login and get cookie
      final protocol = useHttps ? 'https' : 'http';
      final cookie = await login(domain, username, password, protocol);

      final url = Uri.parse('$protocol://$domain/api/v1/trail/upload');
      final request =
          http.MultipartRequest('PUT', url)
            ..headers['Content-Type'] = 'application/gpx+xml'
            ..headers['Cookie'] = '${cookie.name}=${cookie.value}'
            ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();

      if (response.statusCode == 200) {
        logger.i('GPX upload successful');
        Fluttertoast.showToast(
          msg: 'GPX upload successful',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        final responseBody = await response.stream.bytesToString();
        logger.e('GPX upload failed: ${response.statusCode}, $responseBody');
        Fluttertoast.showToast(
          msg: 'GPX upload failed: ${response.statusCode}, $responseBody',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      logger.e('Error during upload: $e');
      Fluttertoast.showToast(
        msg: 'Error during upload: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }
}
