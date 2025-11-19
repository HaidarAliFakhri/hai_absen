// lib/pages/dashboard_page.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hai_absen/pages/detail_page.dart';
import 'package:hai_absen/pages/profile_page.dart';
import 'package:hai_absen/providers/thame_provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../models/attendance_model.dart';
import '../providers/absen_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Timer? _clockTimer;
  Timer? _autoRefreshTimer;
  LatLng? _currentLatLng;
  String? _currentAddress;
  bool _loadingLocation = true;

  String _timeStr = DateFormat('HH:mm:ss').format(DateTime.now());
  final bool _darkMode = false;

  final MobileScannerController _qrController = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  // Chart range
  DateTimeRange? _range;

  // Chart data cached (derived from prov.history)
  Map<String, int> _countsPerDay = {};
  Map<String, int> _statusCounts = {};

  // Greeting
  String greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return "Selamat Pagi";
    if (hour >= 11 && hour < 15) return "Selamat Siang";
    if (hour >= 15 && hour < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    Timer.periodic(const Duration(seconds: 15), (_) {
      _getCurrentLocation();
    });

    // default range = last 30 days
    final now = DateTime.now();
    _range = DateTimeRange(
      start: now.subtract(const Duration(days: 30)),
      end: now,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<AbsenProvider>(context, listen: false);

      // initial fetches
      prov.fetchStats(start: "2025-07-31", end: "2025-12-31");
      prov.fetchProfile();
      prov.fetchHistory();

      // compute charts after data arrives - we'll compute on every provider change in build via _prepareChartData()
      _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _timeStr = DateFormat('HH:mm:ss').format(DateTime.now());
          });
        }
      });

      _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (
        _,
      ) async {
        if (mounted) {
          prov.fetchProfile();
          prov.fetchHistory();
        }
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _autoRefreshTimer?.cancel();
    _qrController.dispose();
    super.dispose();
  }

  bool isWithinWorkingHours() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 8, 0);
    final end = DateTime(now.year, now.month, now.day, 17, 0);
    return now.isAfter(start) && now.isBefore(end);
  }

  Future<bool> _ensureCameraPermission() async {
    final status = await _qrController.start();
    return status != null;
  }

  void _toast(String text) {
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (_) => Container(
          margin: const EdgeInsets.only(bottom: 40, left: 20, right: 20),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (Navigator.canPop(context)) Navigator.pop(context);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _loadingLocation = false);
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _currentLatLng = LatLng(pos.latitude, pos.longitude);

    // Konversi menjadi alamat
    final placemarks = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );

    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      _currentAddress =
          "${p.street}, ${p.subLocality}, ${p.locality}, ${p.subAdministrativeArea}";
    }

    setState(() => _loadingLocation = false);
  }

  Future<void> _openQr(AbsenProvider prov) async {
    if (!await _ensureCameraPermission()) {
      _toast("Izin kamera ditolak");
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Scan QR Absensi")),
          body: MobileScanner(
            controller: _qrController,
            onDetect: (capture) async {
              if (capture.barcodes.isNotEmpty) {
                Navigator.pop(context);
                final res = await prov.checkIn(status: 'masuk');
                _toast(res['body']?['message'] ?? "Absen via QR");
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _shimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _locationCard() {
    if (_loadingLocation) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("Memuat lokasi..."),
        ),
      );
    }

    if (_currentLatLng == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("Lokasi tidak tersedia"),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Lokasi Anda Sekarang",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Text(
              _currentAddress ??
                  "(${_currentLatLng!.latitude}, ${_currentLatLng!.longitude})",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 16),

            // Google Maps Preview
            SizedBox(
              height: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: _currentLatLng!,
                    zoom: 16,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId("me"),
                      position: _currentLatLng!,
                    ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(AbsenProvider prov) {
    final p = prov.profile;
    if (p == null) return _shimmerCard();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundImage: p['profile_photo_url'] != null
                  ? NetworkImage(p['profile_photo_url'])
                  : null,
              child: p['profile_photo_url'] == null
                  ? const Icon(Icons.person, size: 36)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['name'] ?? "-",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text("Batch: ${p['batch_ke'] ?? '-'}"),
                  Text("${p['training_title'] ?? '-'}"),
                ],
              ),
            ),
            Column(
              children: [
                Text(DateFormat('EEEE, dd MMM yyyy').format(DateTime.now())),
                Text(
                  _timeStr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(AbsenProvider prov) {
    final h = prov.todayAttendance;

    String txt = "Belum absen hari ini";
    Color color = Colors.grey.shade300;
    IconData icon = Icons.info;

    if (h != null) {
      if (h.status == 'izin') {
        txt = "Izin Hari Ini\n${h.alasanIzin}";
        color = Colors.orange.shade100;
        icon = Icons.event_busy;
      } else if (h.status == 'masuk') {
        if (h.checkOutTime == null) {
          txt = "Sudah Absen Masuk";
          color = Colors.green.shade100;
          icon = Icons.login;
        } else {
          txt = "Sudah Absen Pulang";
          color = Colors.blue.shade100;
          icon = Icons.logout;
        }
      }
    }

    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                txt,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buttons(AbsenProvider prov) {
    final h = prov.todayAttendance;

    final checkedIn = h?.checkInTime != null;
    final checkedOut = h?.checkOutTime != null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: checkedIn
                    ? null
                    : () async {
                        if (!isWithinWorkingHours()) {
                          _toast("Diluar Jam Kerja");
                          return;
                        }
                        final res = await prov.checkIn(status: 'masuk');
                        _toast(res['body']?['message'] ?? "Absen masuk");
                      },
                icon: const Icon(Icons.login),
                label: const Text("Masuk"),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: !checkedIn || checkedOut
                    ? null
                    : () async {
                        if (!isWithinWorkingHours()) {
                          _toast("Belum saatnya pulang");
                          return;
                        }
                        final res = await prov.checkOut();
                        _toast(res['body']?['message'] ?? "Absen pulang");
                      },
                icon: const Icon(Icons.logout),
                label: const Text("Pulang"),
              ),
            ),
            IconButton(
              onPressed: () => _openQr(prov),
              icon: const Icon(Icons.qr_code_scanner),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final alasan = await _dialogIzin();
              if (alasan != null && alasan.trim().isNotEmpty) {
                final res = await prov.requestIzin(alasan);
                _toast(res['body']?['message'] ?? "Izin berhasil dikirim");
              }
            },
            icon: const Icon(Icons.event_busy),
            label: const Text("Ajukan Izin"),
          ),
        ),
      ],
    );
  }

  Future<String?> _dialogIzin() async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Ajukan Izin"),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Masukkan alasan izin...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text("Kirim"),
            ),
          ],
        );
      },
    );
  }

  Widget _timeline(AbsenProvider prov) {
    if (prov.loading) {
      return Column(children: List.generate(4, (_) => _shimmerCard()));
    }

    if (prov.history.isEmpty) return const Text("Tidak ada riwayat");

    return Column(
      children: prov.history.map((h) {
        final color = h.status == 'izin'
            ? Colors.orange
            : (h.checkOutTime != null ? Colors.blue : Colors.green);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(width: 2, height: 60, color: Colors.grey.shade300),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DetailAbsenPage(data: h)),
                  );
                },
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.attendanceDate,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text("Masuk: ${h.checkInTime ?? '-'}"),
                        Text("Pulang: ${h.checkOutTime ?? '-'}"),
                        Text(h.checkInAddress ?? "-"),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ---------------- CHART HELPERS ----------------

  // Prepare chart data from prov.history filtered by _range
  void _prepareChartData(List<Attendance> history) {
    final Map<String, int> counts = {};
    final Map<String, int> statusCounts = {"masuk": 0, "izin": 0, "lainnya": 0};

    if (_range == null) {
      _countsPerDay = {};
      _statusCounts = statusCounts;
      return;
    }

    final start = DateTime(
      _range!.start.year,
      _range!.start.month,
      _range!.start.day,
    );
    final end = DateTime(_range!.end.year, _range!.end.month, _range!.end.day);

    // Create day keys from start...end (ensure zero entries exist)
    DateTime pointer = start;
    while (!pointer.isAfter(end)) {
      final key = DateFormat('yyyy-MM-dd').format(pointer);
      counts[key] = 0;
      pointer = pointer.add(const Duration(days: 1));
    }

    for (final a in history) {
      try {
        final dt = DateTime.parse(a.attendanceDate);
        if (!dt.isBefore(start) && !dt.isAfter(end)) {
          final key = DateFormat('yyyy-MM-dd').format(dt);
          counts[key] = (counts[key] ?? 0) + 1;

          final st = (a.status ?? "").toLowerCase();
          if (st == 'masuk')
            statusCounts['masuk'] = statusCounts['masuk']! + 1;
          else if (st == 'izin')
            statusCounts['izin'] = statusCounts['izin']! + 1;
          else
            statusCounts['lainnya'] = statusCounts['lainnya']! + 1;
        }
      } catch (e) {
        // ignore parse errors
      }
    }

    _countsPerDay = counts;
    _statusCounts = statusCounts;
  }

  // Build BarChartGroupData
  List<BarChartGroupData> _buildBarGroups() {
    final keys = _countsPerDay.keys.toList()..sort();
    final List<BarChartGroupData> groups = [];
    for (int i = 0; i < keys.length; i++) {
      final v = _countsPerDay[keys[i]] ?? 0;
      groups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 4,
          barRods: [
            BarChartRodData(
              toY: v.toDouble(),
              width: 12,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      );
    }
    return groups;
  }

  // Build pie sections
  List<PieChartSectionData> _buildPieSections(double radius) {
    final masuk = _statusCounts['masuk'] ?? 0;
    final izin = _statusCounts['izin'] ?? 0;
    final lainnya = _statusCounts['lainnya'] ?? 0;
    final total = max(1, masuk + izin + lainnya); // avoid zero division

    final colors = [
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.grey.shade400,
    ];
    return [
      PieChartSectionData(
        value: masuk.toDouble(),
        title: "${((masuk / total) * 100).toStringAsFixed(0)}%",
        color: colors[0],
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: izin.toDouble(),
        title: "${((izin / total) * 100).toStringAsFixed(0)}%",
        color: colors[1],
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: lainnya.toDouble(),
        title: "${((lainnya / total) * 100).toStringAsFixed(0)}%",
        color: colors[2],
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  // Date range picker
  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _range,
      locale: const Locale('id', 'ID'),
    );

    if (picked != null) {
      setState(() {
        _range = picked;
      });
    }
  }

  // Small helper: pretty range text
  String _rangeLabel() {
    if (_range == null) return "Pilih Rentang";
    final f = DateFormat('dd MMM yyyy');
    return "${f.format(_range!.start)} — ${f.format(_range!.end)}";
  }

  // Stats gradient card (modern)
  Widget _statsGradientCard(AbsenProvider prov) {
    final s = prov.stats;
    final totalAbs = (s != null && s['total_absen'] != null)
        ? s['total_absen'].toString()
        : "-";
    final masuk = (s != null && s['total_masuk'] != null)
        ? s['total_masuk'].toString()
        : "-";
    final izin = (s != null && s['total_izin'] != null)
        ? s['total_izin'].toString()
        : "-";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.blue.shade400],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("Total Absen", totalAbs, Icons.check_circle),
          _statItem("Masuk", masuk, Icons.login),
          _statItem("Izin", izin, Icons.event_busy),
        ],
      ),
    );
  }

  Widget _statItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  // ---------------- END CHART HELPERS ----------------
  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AbsenProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);

    // prepare chart data from provider history (history API)
    _prepareChartData(prov.history);

    // bar chart groups
    final barGroups = _buildBarGroups();

    return Theme(
      data: _darkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Hai Absen"),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await prov.fetchProfile();
            await prov.fetchHistory();
            await prov.fetchStats(
              start: _range != null
                  ? DateFormat('yyyy-MM-dd').format(_range!.start)
                  : null,
              end: _range != null
                  ? DateFormat('yyyy-MM-dd').format(_range!.end)
                  : null,
            );
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting + date
                if (prov.profile != null) ...[
                  Text(
                    "${greeting()}, ${prov.profile!['name']} 👋",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Hari ini: ${DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now())}",
                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                ],

                // Profile card + clock
                _profileCard(prov),
                const SizedBox(height: 16),

                // Modern gradient stats card
                _statsGradientCard(prov),
                const SizedBox(height: 16),

                // Status and actions
                _statusCard(prov),
                const SizedBox(height: 16),
                _buttons(prov),
                const SizedBox(height: 18),
                _locationCard(),
                const SizedBox(height: 16),

                // Chart header: date range picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Statistik Absensi",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    // === FIX: Area date + refresh agar tidak overflow ===
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickRange,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Theme.of(context).cardColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_month, size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _rangeLabel(),
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis, // <<< FIX
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 6),

                          // refresh button tetap stabil
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () => prov.fetchHistory(),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                // Charts area (responsive; pie + bar side by side on wide, stacked on narrow)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fullW = constraints.maxWidth;
                    final isNarrow = fullW < 700;

                    // compute pie radius based on available width
                    final pieMaxWidth = isNarrow ? fullW * 0.9 : fullW * 0.35;
                    final pieRadius = (pieMaxWidth / 2).clamp(50.0, 120.0);

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).canvasColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (isNarrow) ...[
                            // stacked: pie then bar
                            SizedBox(
                              height: pieRadius * 2 + 20,
                              child: Center(
                                child: SizedBox(
                                  width: pieRadius * 2,
                                  height: pieRadius * 2,
                                  child: PieChart(
                                    PieChartData(
                                      sections: _buildPieSections(pieRadius),
                                      centerSpaceRadius: pieRadius * 0.3,
                                      sectionsSpace: 6,
                                      startDegreeOffset: -90,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _legendDot(
                                  Colors.green.shade400,
                                  "Masuk",
                                  _statusCounts['masuk'] ?? 0,
                                ),
                                _legendDot(
                                  Colors.orange.shade400,
                                  "Izin",
                                  _statusCounts['izin'] ?? 0,
                                ),
                                _legendDot(
                                  Colors.grey.shade400,
                                  "Lainnya",
                                  _statusCounts['lainnya'] ?? 0,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 240,
                              child: barGroups.isEmpty
                                  ? const Center(
                                      child: Text(
                                        "Tidak ada data pada rentang ini",
                                      ),
                                    )
                                  : ClipRect(),
                            ),
                          ] else ...[
                            // wide: row with pie (left) and bar (right)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  flex: 4,
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: pieRadius * 2 + 10,
                                        child: Center(
                                          child: SizedBox(
                                            width: pieRadius * 2,
                                            height: pieRadius * 2,
                                            child: PieChart(
                                              PieChartData(
                                                sections: _buildPieSections(
                                                  pieRadius,
                                                ),
                                                centerSpaceRadius:
                                                    pieRadius * 0.35,
                                                sectionsSpace: 6,
                                                startDegreeOffset: -90,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _legendDot(
                                            Colors.green.shade400,
                                            "Masuk",
                                            _statusCounts['masuk'] ?? 0,
                                          ),
                                          const SizedBox(width: 12),
                                          _legendDot(
                                            Colors.orange.shade400,
                                            "Izin",
                                            _statusCounts['izin'] ?? 0,
                                          ),
                                          const SizedBox(width: 12),
                                          _legendDot(
                                            Colors.grey.shade400,
                                            "Lainnya",
                                            _statusCounts['lainnya'] ?? 0,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Menampilkan ${_countsPerDay.keys.length} hari (${_range != null ? DateFormat('dd MMM yyyy').format(_range!.start) : '-'} — ${_range != null ? DateFormat('dd MMM yyyy').format(_range!.end) : '-'})",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Riwayat Absensi
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Riwayat Absensi",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tap pada salah satu untuk melihat detail absensi",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                _timeline(prov),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String title, int value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text("$title ($value)"),
      ],
    );
  }
}
