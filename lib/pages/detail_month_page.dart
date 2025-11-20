import 'package:flutter/material.dart';
import 'package:hai_absen/models/attendance_model.dart';
import 'package:intl/intl.dart';

import 'detail_page.dart';

class DetailMonthPage extends StatelessWidget {
  final String month;
  final List<Attendance> list;

  const DetailMonthPage({super.key, required this.month, required this.list});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(month), centerTitle: true),

      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];

          final dateFormatted = DateFormat(
            'dd MMM yyyy',
            'id_ID',
          ).format(DateTime.parse(item.attendanceDate));

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailAbsenPage(data: item)),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDark ? const Color(0xff1e1e1e) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ICON STATUS
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: item.status == "masuk"
                          ? Colors.green.withOpacity(0.18)
                          : item.status == "izin"
                          ? Colors.orange.withOpacity(0.18)
                          : Colors.red.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.status == "masuk"
                          ? Icons.login
                          : item.status == "izin"
                          ? Icons.event_busy
                          : Icons.logout,
                      color: item.status == "masuk"
                          ? Colors.green
                          : item.status == "izin"
                          ? Colors.orange
                          : Colors.red,
                      size: 26,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // TEXT INFO
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFormatted,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          "Masuk: ${item.checkInTime ?? '-'}    "
                          "Pulang: ${item.checkOutTime ?? '-'}",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          item.status?.toUpperCase() ?? '-',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: item.status == "masuk"
                                ? Colors.green
                                : item.status == "izin"
                                ? Colors.orange
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
