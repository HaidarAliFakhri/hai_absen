import 'dart:async';
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

  @override
  void initState() {
    super.initState();

    // Animasi zoom setelah map selesai render
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mapController != null && _center != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _center!, zoom: 16),
          ),
        );
      }
    });
  }

  LatLng? get _center {
    if (widget.data.checkInLat != null && widget.data.checkInLng != null) {
      return LatLng(widget.data.checkInLat!, widget.data.checkInLng!);
    }
    return null;
  }

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


    // Data posisi
    final LatLng? posIn = (d.checkInLat != null && d.checkInLng != null)
        ? LatLng(d.checkInLat!, d.checkInLng!)
        : null;

    final LatLng? posOut = (d.checkOutLat != null && d.checkOutLng != null)
        ? LatLng(d.checkOutLat!, d.checkOutLng!)
        : null;

    // ======= MARKER =======
   final Set<Marker> markers = {
  if (posIn != null)
    Marker(
      markerId: const MarkerId("checkin"),
      position: posIn,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: "Check-In"),
    ),

  if (posOut != null)
    Marker(
      markerId: const MarkerId("checkout"),
      position: posOut,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: "Check-Out"),
    ),
};


    // ======= POLYLINE (GARIS DARI IN → OUT) =======
    final polylines = <Polyline>{
      if (posIn != null && posOut != null)
        Polyline(
          polylineId: const PolylineId("route"),
          points: [posIn, posOut],
          width: 5,
          color: Colors.blueAccent,
        ),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Absensi"),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: isDark ? const Color(0xff121212) : Colors.grey[200],

      body: SingleChildScrollView(
        child: Column(
          children: [
            // =================================================
            // ===================== MAP ========================
            // =================================================
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 330,
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: posIn ?? const LatLng(-6.2, 106.8),
                          zoom: 15,
                        ),
                        markers: markers.toSet(),
                        polylines: polylines,
                        onMapCreated: (c) => mapController = c,
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                      ),

                      // Label floating untuk titik Check-In & Check-Out
                      if (posIn != null)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: _floatingLabel(
                            "Lokasi Check-In",
                            Colors.green.shade700,
                          ),
                        ),

                      if (posOut != null)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: _floatingLabel(
                            "Lokasi Check-Out",
                            Colors.red.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // =================================================
            // ================== DETAIL CARD ==================
            // =================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _modernCard(
                    title: "Check-In",
                    color: Colors.green,
                    icon: Icons.login,
                    time: d.checkInTime ?? "-",
                    address: d.checkInAddress ?? "-",
                    pos: posIn,
                  ),

                  const SizedBox(height: 18),

                  _modernCard(
                    title: "Check-Out",
                    color: Colors.red,
                    icon: Icons.logout,
                    time: d.checkOutTime ?? "-",
                    address: d.checkOutAddress ?? "-",
                    pos: posOut,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // ===================== MODERN CARD =========================
  // ===========================================================
  Widget _modernCard({
    required String title,
    required Color color,
    required IconData icon,
    required String time,
    required String address,
    required LatLng? pos,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _infoRow(Icons.access_time, "Waktu", time),
          const SizedBox(height: 10),
          _infoRow(Icons.location_on, "Alamat", address),

          const SizedBox(height: 16),

          // BUTTON GOOGLE MAPS
          if (pos != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.map_outlined),
                label: const Text("Buka di Google Maps"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final url =
                      "https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}";
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 8),
        Text(
          "$title: ",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }

  // Label kecil di atas Map
  Widget _floatingLabel(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
