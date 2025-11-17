import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  Widget build(BuildContext context) {
    final d = widget.data;

    final double? lat = d.checkInLat;
    final double? lng = d.checkInLng;

    final LatLng center = LatLng(
      lat ?? -6.2,
      lng ?? 106.8,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Absensi")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // MAP
            Container(
              height: 300,
              width: double.infinity,
              child: GoogleMap(
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
                onMapCreated: (c) => mapController = c,
              ),
            ),

            const SizedBox(height: 20),

            // DATA ABSENSI
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tanggal : ${d.attendanceDate}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 10),

                      Text("Masuk : ${d.checkInTime ?? '-'}"),
                      Text("Pulang : ${d.checkOutTime ?? '-'}"),
                      const SizedBox(height: 6),

                      Text("Alamat cek-in : ${d.checkInAddress ?? '-'}"),
                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        onPressed: () async {
                          final url =
                              "https://www.google.com/maps/search/?api=1&query=$lat,$lng";

                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url),
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.map),
                        label: const Text("Buka di Google Maps"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
