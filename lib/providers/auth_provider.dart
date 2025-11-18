import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/api_service.dart';
import '../core/shared_prefs.dart';

class AuthProvider with ChangeNotifier {
  Map<String, dynamic>? user;
  bool loading = false;

  // For register page
  bool loadingBatches = false;
  bool loadingTrainings = false;
  List<dynamic> batches = []; // each batch contains trainings list
  List<dynamic> trainings = []; // global trainings (fallback)

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
      notifyListeners();
      return false;
    }
  }

  // =====================
  // FETCH BATCHES (with trainings inside)
  // try multiple endpoints as fallback
  // =====================
  Future<bool> fetchBatches() async {
    loadingBatches = true;
    notifyListeners();

    try {
      // try first endpoint (common)
      var res = await ApiService.get("/batch"); // try /batch
      if (res.statusCode == 404) {
        // fallback
        res = await ApiService.get("/batches");
      }

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        // Expect body['data'] is list
        final list = body['data'] ?? [];
        batches = list as List<dynamic>;
        loadingBatches = false;
        notifyListeners();
        return true;
      } else {
        // try second fallback (sometimes api returns /api/batch/list)
        // you can add more fallbacks here if your backend differs
        loadingBatches = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      loadingBatches = false;
      notifyListeners();
      return false;
    }
  }

  // =====================
  // FETCH GLOBAL TRAININGS (fallback)
  // =====================
  Future<bool> fetchTrainings() async {
    loadingTrainings = true;
    notifyListeners();

    try {
      var res = await ApiService.get("/trainings"); // try /trainings
      if (res.statusCode == 404) {
        res = await ApiService.get("/training");
      }

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = body['data'] ?? [];
        trainings = list as List<dynamic>;
        loadingTrainings = false;
        notifyListeners();
        return true;
      } else {
        loadingTrainings = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      loadingTrainings = false;
      notifyListeners();
      return false;
    }
  }
}
