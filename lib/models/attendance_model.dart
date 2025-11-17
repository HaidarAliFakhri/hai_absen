class Attendance {
  final int id;
  final String attendanceDate;
  final String? checkInTime;
  final String? checkOutTime;
  final double? checkInLat;
  final double? checkInLng;
  final double? checkOutLat;
  final double? checkOutLng;
  final String? checkInAddress;
  final String? checkOutAddress;
  final String? status;
  final String? alasanIzin;

  Attendance({
    required this.id,
    required this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLat,
    this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
    this.checkInAddress,
    this.checkOutAddress,
    this.status,
    this.alasanIzin,
  });

  factory Attendance.fromJson(Map<String, dynamic> j) => Attendance(
        id: j['id'],
        attendanceDate: j['attendance_date'] ?? j['attendanceDate'],
        checkInTime: j['check_in_time'] ?? j['check_in'],
        checkOutTime: j['check_out_time'] ?? j['check_out'],
        checkInLat: j['check_in_lat'] != null ? (j['check_in_lat'] as num).toDouble() : null,
        checkInLng: j['check_in_lng'] != null ? (j['check_in_lng'] as num).toDouble() : null,
        checkOutLat: j['check_out_lat'] != null ? (j['check_out_lat'] as num).toDouble() : null,
        checkOutLng: j['check_out_lng'] != null ? (j['check_out_lng'] as num).toDouble() : null,
        checkInAddress: j['check_in_address'],
        checkOutAddress: j['check_out_address'],
        status: j['status'],
        alasanIzin: j['alasan_izin'],
      );
}
