import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' as html_parser;

class MainViewModel extends ChangeNotifier {
  var logger = Logger();
  late StreamSubscription _intentSub;
  final _sharedFiles = <SharedMediaFile>[];

  /// Dispose the sharing intent
  void disposeSharingIntent() {
    logger.i('Disposing sharing intent');
    _intentSub.cancel();
  }

  /// Initialise the sharing intent
  void initialiseSharingInten() {
    logger.i('Initialising sharing intent');
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (value) {
        _handleSharedFiles(value);
      },
      onError: (err) {
        logger.e("getIntentDataStream error: $err");
      },
    );

    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      _handleSharedFiles(value);
      ReceiveSharingIntent.instance.reset();
    });
  }

  /// Handle shared files
  ///
  /// Parameters:
  ///
  /// - `files`: The list of shared files
  void _handleSharedFiles(List<SharedMediaFile> files) {
    _sharedFiles.clear();
    _sharedFiles.addAll(files);
    logger.i(_sharedFiles.map((f) => f.toMap()).toString());
    notifyListeners();

    for (var file in _sharedFiles) {
      if (file.path.endsWith('.gpx') ||
          file.path.endsWith('.json') ||
          file.path.endsWith('.fit') ||
          file.path.endsWith('.kml')) {
        uploadGpx(file.path);
      } else {
        logger.i('Ignoring non-GPX file: ${file.path}');
        Fluttertoast.showToast(
          msg: 'Only GPX, JSON, FIT and KML files are supported',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  /// Login to wanderer
  ///
  /// Parameters:
  ///
  /// - `domain`: The domain of the wanderer instance
  /// - `username`: The username
  /// - `password`: The password
  /// - `protocol`: The protocol to use (http or https)
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
      final cookies = response.headers['set-cookie'];
      if (cookies != null) {
        return Cookie.fromSetCookieValue(cookies);
      } else {
        throw Exception('No cookies found in response');
      }
    } else {
      logger.e('Login failed: ${response.body}');
      throw Exception('Login failed');
    }
  }

  /// Upload a GPX file to wanderer
  ///
  /// Parameters:
  ///
  /// - `filePath`: The path to the GPX file
  Future<void> uploadGpx(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final domain = prefs.getString('domain') ?? '';
    final username = prefs.getString('username') ?? '';
    final password = prefs.getString('password') ?? '';
    final useHttps = prefs.getBool('useHttps') ?? false;

    if (domain.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        filePath.isEmpty) {
      logger.e('Missing credentials');
      return;
    }

    try {
      final protocol = useHttps ? 'https' : 'http';
      final cookie = await login(domain, username, password, protocol);
      final url = Uri.parse('$protocol://$domain/api/v1/trail/upload');
      final request =
          http.MultipartRequest('PUT', url)
            ..headers['Content-Type'] = 'application/gpx+xml'
            ..headers['Cookie'] = '${cookie.name}=${cookie.value}'
            ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();
      await _handleUploadResponse(response);
    } catch (e) {
      logger.e('Error during upload: $e');
      Fluttertoast.showToast(
        msg: 'Error during upload: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  /// Handle the upload response
  ///
  /// Parameters:
  ///
  /// - `response`: The response from the upload request
  Future<void> _handleUploadResponse(http.StreamedResponse response) async {
    if (response.statusCode == 200) {
      logger.i('GPX upload successful');
      Fluttertoast.showToast(
        msg: 'GPX upload successful',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } else {
      final responseBody = await response.stream.bytesToString();
      final document = html_parser.parse(responseBody);
      final messageElement = document.querySelector('.message h1');
      final message =
          messageElement != null ? messageElement.text : 'Unknown error';
      logger.e('GPX upload failed: ${response.statusCode}, $message');
      Fluttertoast.showToast(
        msg: 'GPX upload failed: $message',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }
}
