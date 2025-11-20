import 'package:flutter/material.dart';
import 'package:hai_absen/models/attendance_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/absen_provider.dart';
import 'detail_page.dart';

class DetailListPage extends StatefulWidget {
  const DetailListPage({super.key});

  @override
  State<DetailListPage> createState() => _DetailListPageState();
}

class _DetailListPageState extends State<DetailListPage>
    with SingleTickerProviderStateMixin {
  DateTime _selectedMonth = DateTime.now();
  // animation controller used for subtle animations if needed
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<AbsenProvider>(context, listen: false).fetchHistory();
    });

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
  }

  // create list of weekdays short names in Indonesian
  List<String> _weekDaysShort() {
    // starting from Mon..Sun or Sun..Sat; here we use Senin..Minggu (Mon..Sun)
    return ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  }

  Color _cellColorForAttendance(Attendance? a, DateTime cellDate) {
    final now = DateTime.now();
    // Today highlight
    if (cellDate.year == now.year &&
        cellDate.month == now.month &&
        cellDate.day == now.day) {
      return Colors.blue.shade400;
    }

    if (a == null) return Colors.transparent;

    // Prioritize izin
    if (a.status == 'izin') return Colors.yellow.shade600;
    // if hadir lengkap (both check-in & check-out)
    if (a.checkInTime != null && a.checkOutTime != null) {
      return Colors.green.shade600;
    }
    // else alpha / incomplete
    return Colors.red.shade400;
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          _legendItem(Colors.green.shade600, "Hadir"),
          const SizedBox(width: 10),
          _legendItem(Colors.red.shade400, "Alpha"),
          const SizedBox(width: 10),
          _legendItem(Colors.yellow.shade600, "Izin"),
          const SizedBox(width: 10),
          _legendItem(Colors.blue.shade400, "Hari ini"),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AbsenProvider>(context);

    // If no history yet, show scaffold but still allow fetch
    if (prov.history.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Riwayat Absensi (Kalender)")),
        body: const Center(child: Text("Memuat riwayat...")),
      );
    }

    // filter history for selected month
    final monthHistory = prov.history.where((item) {
      try {
        final d = DateTime.parse(item.attendanceDate);
        return d.year == _selectedMonth.year && d.month == _selectedMonth.month;
      } catch (e) {
        return false;
      }
    }).toList();

    // map day number -> Attendance
    final Map<int, Attendance> byDay = {};
    for (final a in monthHistory) {
      try {
        final d = DateTime.parse(a.attendanceDate);
        byDay[d.day] = a;
      } catch (e) {
        // ignore parse error
      }
    }

    final firstOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final totalDaysInMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
    final firstWeekday = firstOfMonth.weekday; // 1 = Mon ... 7 = Sun

    // Build a list of DateTimes representing the grid cells (including leading blanks)
    final List<DateTime?> gridDays = [];

    // We want the calendar to start on Monday (weekday == 1)
    final leadingEmpty =
        (firstWeekday - 1) % 7; // number of blanks before day 1
    for (int i = 0; i < leadingEmpty; i++) gridDays.add(null);
    for (int d = 1; d <= totalDaysInMonth; d++) {
      gridDays.add(DateTime(_selectedMonth.year, _selectedMonth.month, d));
    }
    // pad trailing to complete rows of 7
    while (gridDays.length % 7 != 0) gridDays.add(null);

    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Absensi")),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // month header with AnimatedSwitcher (animates the label)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Expanded(
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity == null) return;
                      // swipe left -> negative velocity -> next month
                      if (details.primaryVelocity! < -150) {
                        _changeMonth(1);
                      } else if (details.primaryVelocity! > 150) {
                        _changeMonth(-1);
                      }
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) {
                        final inAnim = Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(anim);
                        return SlideTransition(
                          position: inAnim,
                          child: FadeTransition(opacity: anim, child: child),
                        );
                      },
                      child: Text(
                        DateFormat("MMMM yyyy", "id_ID").format(_selectedMonth),
                        key: ValueKey<String>(
                          DateFormat("yyyy-MM").format(_selectedMonth),
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // legend
          _buildLegend(),

          const SizedBox(height: 6),

          // Weekday labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: _weekDaysShort()
                  .map(
                    (w) => Expanded(
                      child: Center(
                        child: Text(
                          w,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Animated month grid (switches content with fade+slide)
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) {
                final offsetAnim = Tween<Offset>(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(anim);
                return SlideTransition(
                  position: offsetAnim,
                  child: FadeTransition(opacity: anim, child: child),
                );
              },
              child: GestureDetector(
                // also allow swiping on grid to change month
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  if (details.primaryVelocity! < -120) {
                    _changeMonth(1);
                  } else if (details.primaryVelocity! > 120) {
                    _changeMonth(-1);
                  }
                },
                // key needed so AnimatedSwitcher recognizes different months
                key: ValueKey<String>(
                  DateFormat("yyyy-MM").format(_selectedMonth),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: gridDays.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 1,
                        ),
                    itemBuilder: (context, index) {
                      final cellDate = gridDays[index];
                      if (cellDate == null) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      }

                      final day = cellDate.day;
                      final attendance = byDay[day];
                      final bg = _cellColorForAttendance(attendance, cellDate);
                      final isToday =
                          DateTime.now().year == cellDate.year &&
                          DateTime.now().month == cellDate.month &&
                          DateTime.now().day == cellDate.day;

                      // small icon selection
                      Widget? statusIcon;
                      if (attendance != null) {
                        if (attendance.status == 'izin') {
                          statusIcon = const Icon(
                            Icons.event_busy,
                            size: 14,
                            color: Colors.black87,
                          );
                        } else if (attendance.checkInTime != null &&
                            attendance.checkOutTime != null) {
                          statusIcon = const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          );
                        } else {
                          statusIcon = const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          );
                        }
                      }

                      return GestureDetector(
                        onTap: () {
                          if (attendance != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetailAbsenPage(data: attendance),
                              ),
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: bg == Colors.transparent ? Colors.white : bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isToday
                                  ? Colors.blue.shade900
                                  : Colors.grey.shade200,
                              width: isToday ? 2 : 0.6,
                            ),
                            boxShadow: [
                              if (bg != Colors.transparent)
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // day number
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Text(
                                  "$day",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: bg == Colors.transparent
                                        ? Colors.black87
                                        : (isToday
                                              ? Colors.white
                                              : Colors.white),
                                  ),
                                ),
                              ),

                              // icon bottom-right
                              if (statusIcon != null)
                                Positioned(
                                  right: 6,
                                  bottom: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: statusIcon,
                                  ),
                                ),

                              // small subtitle (time) on center if exists
                              if (attendance != null)
                                Positioned(
                                  left: 6,
                                  bottom: 6,
                                  right: 28,
                                  child: Text(
                                    (attendance.checkInTime ?? '-') +
                                        (attendance.checkOutTime != null
                                            ? ' • ${attendance.checkOutTime}'
                                            : ''),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: bg == Colors.transparent
                                          ? Colors.black54
                                          : Colors.white70,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            "Create by: Haidar Ali Fakhri",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
