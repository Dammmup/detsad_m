import '../models/child_model.dart';
import '../models/attendance_model.dart';

class AttendanceRecord {
  final Attendance attendance;
  final Child child;

  AttendanceRecord({required this.attendance, required this.child});

  String get status => attendance.status;
}
