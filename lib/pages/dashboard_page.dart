import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hai_absen/pages/detail_page.dart';
import 'package:hai_absen/pages/profile_page.dart';
import 'package:hai_absen/providers/thame_provider.dart';
import 'package:hai_absen/widgets/qr_scanner_page.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../providers/absen_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Timer? _clockTimer;
  Timer? _autoRefreshTimer;

  String _timeStr = DateFormat('HH:mm:ss').format(DateTime.now());

  final bool _darkMode = false;

  final MobileScannerController _qrController = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  @override
  void initState() {
    super.initState();
    final prov = Provider.of<AbsenProvider>(context, listen: false);

    prov.fetchProfile();
    prov.fetchHistory();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _timeStr = DateFormat('HH:mm:ss').format(DateTime.now());
        });
      }
    });

    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (mounted) {
        prov.fetchProfile();
        prov.fetchHistory();
      }
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

  // Permission dialog
  Future<bool> _ensureCameraPermission() async {
    final status = await _qrController.start();

    return status != null;
  }

  // Toast
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

  // QR Scanner Fullscreen
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
          appBar: AppBar(
            title: const Text("Scan QR Absensi"),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QRScannerPage()),
                  );

                  if (result != null) {
                    final res = await prov.checkIn(status: 'masuk');
                    _toast(res['body']?['message'] ?? "Absen via QR");
                  }
                },
              ),
            ],
          ),
          body: MobileScanner(
            controller: _qrController,
            onDetect: (capture) async {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                Navigator.pop(context);
                _toast("QR Terdeteksi, Mengirim absen...");

                final res = await prov.checkIn(status: 'masuk');
                if (res['ok'] == true) {
                  _toast("Absen via QR berhasil");
                } else {
                  _toast("Gagal absen via QR");
                }
              }
            },
          ),
        ),
      ),
    );
  }

  // SHIMMER
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

  // PROFILE CARD
  Widget _profileCard(AbsenProvider prov) {
    final p = prov.profile;
    if (p == null) return _shimmerCard();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Hero(
              tag: "profile-photo",
              child: CircleAvatar(
                radius: 35,
                backgroundImage: p['profile_photo_url'] != null
                    ? NetworkImage(p['profile_photo_url'])
                    : null,
                child: p['profile_photo_url'] == null
                    ? const Icon(Icons.person, size: 36)
                    : null,
              ),
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

  // STATUS CARD
  Widget _statusCard(AbsenProvider prov) {
    final h = prov.todayAttendance;

    String txt = "Belum absen hari ini";
    Color color = Colors.grey.shade300;
    IconData icon = Icons.info;

    if (h != null) {
      if (h.status == 'masuk') {
        if (h.checkOutTime == null) {
          txt = "Sudah Absen Masuk";
          color = Colors.green.shade100;
          icon = Icons.login;
        } else {
          txt = "Sudah Absen Pulang";
          color = Colors.blue.shade100;
          icon = Icons.logout;
        }
      } else if (h.status == 'izin') {
        txt = "Izin: ${h.alasanIzin}";
        color = Colors.orange.shade100;
        icon = Icons.event_busy;
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

  // ACTION BUTTONS
  Widget _buttons(AbsenProvider prov) {
    final h = prov.todayAttendance;

    final checkedIn = h?.checkInTime != null;
    final checkedOut = h?.checkOutTime != null;

    return Row(
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
    );
  }

  // TIMELINE RIWAYAT
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

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AbsenProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);

    return Theme(
      data: _darkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Hai Absen"),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: "Pengaturan Profil",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),

            IconButton(
              icon: Icon(themeProv.isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                themeProv.toggleTheme(); // ← ini sekarang bekerja normal
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await prov.fetchProfile();
            await prov.fetchHistory();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _profileCard(prov),
                const SizedBox(height: 16),
                _statusCard(prov),
                const SizedBox(height: 16),
                _buttons(prov),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Riwayat Absensi",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
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
}
