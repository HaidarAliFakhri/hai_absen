import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../core/api_service.dart';
import '../models/attendance_model.dart';

class AbsenProvider with ChangeNotifier {
  bool loading = false;
  bool actionLoading = false;
  Map<String, dynamic>? profile;
  List<Attendance> history = [];
  Attendance? todayAttendance; // attendance record for today if exists

  // ---------- Helper: get current position ----------
  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied forever');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // ---------- Helper: reverse geocode to address ----------
  Future<String> _addressFromCoords(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          if (p.street != null && p.street!.isNotEmpty) p.street,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality,
          if (p.subAdministrativeArea != null && p.subAdministrativeArea!.isNotEmpty) p.subAdministrativeArea,
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) p.administrativeArea,
          if (p.country != null && p.country!.isNotEmpty) p.country,
        ];
        return parts.join(', ');
      }
    } catch (e) {
      // fallback
    }
    return "$lat,$lng";
  }

  // ---------- Fetch profile ----------
  Future<void> fetchProfile() async {
    loading = true;
    notifyListeners();
    try {
      final res = await ApiService.get('/profile');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        profile = body['data'] ?? body;
      } else if (res.statusCode == 401) {
        profile = null;
      }
    } catch (e) {
      // ignore
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ---------- Fetch history ----------
  Future<void> fetchHistory() async {
    loading = true;
    notifyListeners();
    try {
      final res = await ApiService.get('/absen/history');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final list = (body['data'] ?? []) as List;
        history = list.map((e) => Attendance.fromJson(e)).toList();
        _findToday();
      } else {
        history = [];
        todayAttendance = null;
      }
    } catch (e) {
      history = [];
      todayAttendance = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ---------- find today's attendance ----------
  void _findToday() {
  final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  try {
    todayAttendance = history.firstWhere(
      (h) => h.attendanceDate == todayStr,
    );
  } catch (e) {
    todayAttendance = null;
  }
}


  // ---------- Check In ----------
  Future<Map<String, dynamic>> checkIn({String status = 'masuk', String? alasanIzin}) async {
    actionLoading = true;
    notifyListeners();
    try {
      // get position
      final pos = await _determinePosition();
      final lat = pos.latitude;
      final lng = pos.longitude;
      final address = await _addressFromCoords(lat, lng);

      final now = DateTime.now();
      final body = {
        "attendance_date": DateFormat('yyyy-MM-dd').format(now),
        "check_in": DateFormat('HH:mm').format(now),
        "check_in_lat": lat,
        "check_in_lng": lng,
        "check_in_address": address,
        "status": status,
        if (status == 'izin' && (alasanIzin ?? "").isNotEmpty) "alasan_izin": alasanIzin,
      };

      final res = await ApiService.post('/absen/check-in', body);
      final parsed = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        // refresh history
        await fetchHistory();
        actionLoading = false;
        notifyListeners();
        return {"ok": true, "body": parsed};
      } else {
        actionLoading = false;
        notifyListeners();
        return {"ok": false, "body": parsed, "statusCode": res.statusCode};
      }
    } catch (e) {
      actionLoading = false;
      notifyListeners();
      return {"ok": false, "error": e.toString()};
    }
  }

  // ---------- Check Out ----------
  Future<Map<String, dynamic>> checkOut() async {
    actionLoading = true;
    notifyListeners();
    try {
      final pos = await _determinePosition();
      final lat = pos.latitude;
      final lng = pos.longitude;
      final address = await _addressFromCoords(lat, lng);

      final now = DateTime.now();
      final body = {
        "attendance_date": DateFormat('yyyy-MM-dd').format(now),
        "check_out": DateFormat('HH:mm').format(now),
        "check_out_lat": lat,
        "check_out_lng": lng,
        "check_out_location": "$lat,$lng",
        "check_out_address": address,
      };

      final res = await ApiService.post('/absen/check-out', body);
      final parsed = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchHistory();
        actionLoading = false;
        notifyListeners();
        return {"ok": true, "body": parsed};
      } else {
        actionLoading = false;
        notifyListeners();
        return {"ok": false, "body": parsed, "statusCode": res.statusCode};
      }
    } catch (e) {
      actionLoading = false;
      notifyListeners();
      return {"ok": false, "error": e.toString()};
    }
  }

  // ---------- Izin ----------
  Future<Map<String, dynamic>> requestIzin(String alasan) async {
    actionLoading = true;
    notifyListeners();
    try {
      final now = DateTime.now();
      final body = {
        "attendance_date": DateFormat('yyyy-MM-dd').format(now),
        "alasan_izin": alasan,
      };

      final res = await ApiService.post('/izin', body);
      final parsed = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchHistory();
        actionLoading = false;
        notifyListeners();
        return {"ok": true, "body": parsed};
      } else {
        actionLoading = false;
        notifyListeners();
        return {"ok": false, "body": parsed, "statusCode": res.statusCode};
      }
    } catch (e) {
      actionLoading = false;
      notifyListeners();
      return {"ok": false, "error": e.toString()};
    }
  }
    // ---------- Update profile (data non-file) ----------
  Future<bool> updateProfile(Map<String, dynamic> body) async {
    actionLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.post('/profile/update', body);
      final parsed = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        // refresh local profile
        await fetchProfile();
        actionLoading = false;
        notifyListeners();
        return true;
      } else {
        // optional: you can inspect parsed['message']
        actionLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      actionLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ---------- Upload photo ----------
  Future<bool> uploadPhoto(File file) async {
    actionLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.uploadFile('/profile/upload-photo', file, fieldName: 'photo');
      // if server returns 200 and JSON body
      if (res.statusCode == 200 || res.statusCode == 201) {
        // refresh profile to get new photo url
        await fetchProfile();
        actionLoading = false;
        notifyListeners();
        return true;
      } else {
        actionLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      actionLoading = false;
      notifyListeners();
      return false;
    }
  }

}
