import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/absen_provider.dart';
import 'detail_page.dart';

class DetailListPage extends StatefulWidget {
  const DetailListPage({super.key});

  @override
  State<DetailListPage> createState() => _DetailListPageState();
}

class _DetailListPageState extends State<DetailListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AbsenProvider>(context, listen: false).fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AbsenProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Absensi")),
      body: prov.history.isEmpty
          ? const Center(child: Text("Belum ada riwayat"))
          : ListView.builder(
              itemCount: prov.history.length,
              itemBuilder: (ctx, i) {
                final item = prov.history[i];

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Icon(
                      item.status == "masuk"
                          ? Icons.login
                          : item.status == "izin"
                              ? Icons.event_busy
                              : Icons.logout,
                      color: Colors.blue,
                    ),

                    title: Text(item.attendanceDate),
                    subtitle: Text(
                      "Masuk: ${item.checkInTime ?? '-'}"
                      "\nPulang: ${item.checkOutTime ?? '-'}",
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailAbsenPage(data: item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
