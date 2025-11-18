import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'constants.dart';
import 'shared_prefs.dart';

class ApiService {
  static Future<Map<String, String>> _headers() async {
    final token = await LocalStorage.getToken();
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  static Future<http.Response> post(String path, Map data) async {
    final url = Uri.parse("${Constants.baseUrl}$path");
    final headers = await _headers();
    return await http.post(url, headers: headers, body: jsonEncode(data));
  }

  static Future<http.Response> get(String path) async {
    final url = Uri.parse("${Constants.baseUrl}$path");
    final headers = await _headers();
    return await http.get(url, headers: headers);
  }

  // ------------------ ADD THIS ------------------
  static Future<http.Response> uploadFile(
    String path,
    File file, {
    String fieldName = 'photo',
  }) async {
    final url = Uri.parse("${Constants.baseUrl}$path");
    final token = await LocalStorage.getToken();

    var request = http.MultipartRequest("POST", url);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    // optional: accept json response
    request.headers['Accept'] = 'application/json';

    request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));

    final streamed = await request.send();
    return await http.Response.fromStream(streamed);
  }

  static Future<http.Response> put(String path, Map data) async {
    final url = Uri.parse("${Constants.baseUrl}$path");
    final headers = await _headers();
    return await http.put(url, headers: headers, body: jsonEncode(data));
  }
}
