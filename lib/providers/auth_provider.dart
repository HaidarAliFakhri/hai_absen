import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/api_service.dart';
import '../core/shared_prefs.dart';

class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? user;
  bool loading = false;

  // =====================
  // REGISTER
  // =====================
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    loading = true;
    notifyListeners();

    final res = await ApiService.post("/register", data);
    final body = jsonDecode(res.body);

    loading = false;
    notifyListeners();

    return {"status": res.statusCode, "body": body};
  }

  // =====================
  // LOGIN
  // =====================
  Future<bool> login(String email, String password) async {
    loading = true;
    notifyListeners();

    final res = await ApiService.post("/login", {
      "email": email,
      "password": password,
    });

    loading = false;

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);

      final token = body["data"]["token"];
      final usr = body["data"]["user"];

      await LocalStorage.saveToken(token);
      user = usr;

      notifyListeners();
      return true;
    } else {
      return false;
    }
  }
}
