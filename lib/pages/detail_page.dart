import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/attendance_model.dart';

class DetailAbsenPage extends StatefulWidget {
  final Attendance data;

  const DetailAbsenPage({super.key, required this.data});

  @override
  State<DetailAbsenPage> createState() => _DetailAbsenPageState();
}

class _DetailAbsenPageState extends State<DetailAbsenPage> {
  GoogleMapController? mapController;

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return '-';
    try {
      final d = DateTime.parse(date);
      return DateFormat("EEEE, dd MMMM yyyy", "id_ID").format(d);
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColorPrimary = isDark ? Colors.white : Colors.black87;
    final textColorSecondary = isDark ? Colors.white70 : Colors.black54;

    final double lat = d.checkInLat ?? -6.2;
    final double lng = d.checkInLng ?? 106.8;

    final LatLng center = LatLng(lat, lng);
    final statusText = (d.status ?? '').toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Absensi"),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: isDark
          ? const Color(0xff121212)
          : const Color(0xfff5f7fa),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // ===== MAP SECTION =====
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  height: 280,
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: center,
                          zoom: 16,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId("checkin"),
                            position: center,
                            infoWindow: InfoWindow(
                              title: "Lokasi Absen",
                              snippet: d.checkInAddress ?? "",
                            ),
                          ),
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                      ),

                      // Overlay alamat
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withOpacity(0.65)
                                : Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: isDark ? Colors.white : Colors.black87,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  d.checkInAddress ?? "Tidak ada alamat",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ===== CARD DETAIL =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: isDark ? const Color(0xff1f1f1f) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: isDark ? 1 : 3,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // DATE + STATUS
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            color: Colors.blue.shade300,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              formatDate(d.attendanceDate),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColorPrimary,
                              ),
                            ),
                          ),
                          Chip(
                            backgroundColor: d.status == "masuk"
                                ? Colors.green.withOpacity(0.2)
                                : d.status == "izin"
                                ? Colors.orange.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.3),
                            label: Text(
                              statusText,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: d.status == "masuk"
                                    ? Colors.green.shade400
                                    : d.status == "izin"
                                    ? Colors.orange.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      InfoRow(
                        icon: Icons.login,
                        title: "Jam Masuk",
                        value: d.checkInTime ?? '-',
                        color: Colors.green,
                        dark: isDark,
                      ),

                      const SizedBox(height: 12),

                      InfoRow(
                        icon: Icons.logout,
                        title: "Jam Pulang",
                        value: d.checkOutTime ?? '-',
                        color: Colors.red,
                        dark: isDark,
                      ),

                      const SizedBox(height: 20),

                      Text(
                        "Alamat Lokasi",
                        style: TextStyle(
                          fontSize: 14,
                          color: textColorSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d.checkInAddress ?? "-",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColorPrimary,
                        ),
                      ),

                      const SizedBox(height: 22),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.map_outlined),
                              label: const Text("Google Maps"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                final url =
                                    "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

/// Reusable modern row widget for light/dark mode
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool dark;

  const InfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.color = Colors.blue,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = dark ? Colors.white : Colors.black87;
    final secondary = dark ? Colors.white70 : Colors.black54;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: secondary, fontSize: 13)),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
