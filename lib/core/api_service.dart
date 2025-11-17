import 'dart:convert';

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
}
