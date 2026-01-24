import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://detsad-b.vercel.app/';
    } else {
      // Для локальной разработки на мобильном устройстве используем localhost
      // Если вы тестируете на физическом устройстве, замените на IP-адрес компьютера
      return 'https://detsad-b.vercel.app/';
      // return 'http://10.0.2.2:8080'; // Для эмулятора Android
    }
  }

  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String validateToken = '/auth/validate';
  static const String currentUser = '/auth/current-user';

  static const String users = '/users';
  static String userById(String id) => '/users/$id';
  static const String subscribeFCM = '/users/push/fcm/subscribe';
  static const String unsubscribeFCM = '/users/push/fcm/unsubscribe';

  static const String children = '/children';
  static String childById(String id) => '/children/$id';
  static String childrenByGroup(String groupId) => '/children/group/$groupId';

  static const String groups = '/groups';
  static String groupById(String id) => '/groups/$id';

  static const String childAttendance = '/child-attendance';
  static const String childAttendanceBulk = '/child-attendance/bulk';
  static const String childAttendanceStats = '/child-attendance/stats';

  static const String clockIn = '/attendance/clock-in';
  static const String clockOut = '/attendance/clock-out';
  static const String breakStart = '/attendance/break-start';
  static const String breakEnd = '/attendance/break-end';
  static const String attendanceEntries = '/attendance/entries';
  static const String attendanceSummary = '/attendance/summary';

  static const String staffShifts = '/staff-shifts';
  static const String staffShiftsBulk = '/staff-shifts/bulk';
  static String staffShiftCheckin(String shiftId) =>
      '/staff-shifts/checkin/$shiftId';
  static String staffShiftCheckout(String shiftId) =>
      '/staff-shifts/checkout/$shiftId';

  static const String staffAttendanceTracking = '/staff-time-tracking';
  static String staffAttendanceTrackingByStaff(String staffId) =>
      '/staff-time-tracking/staff/$staffId';
  static String staffAttendanceTrackingById(String id) =>
      '/staff-time-tracking/$id';

  static const String schedule = '/schedule';
  static String scheduleByStaff(String staffId) => '/schedule/staff/$staffId';
  static String scheduleByGroup(String groupId) => '/schedule/group/$groupId';

  static const String settingsKindergarten = '/settings/kindergarten';
  static const String settingsGeolocation = '/settings/geolocation';

  static const String mainEvents = '/main-events';
  static String mainEventById(String id) => '/main-events/$id';

  static const String childPayments = '/child-payments';
  static String childPaymentById(String id) => '/child-payments/$id';
  static String childPaymentsByPeriod(String period) =>
      '/child-payments/period/$period';

  static const String taskList = '/task-list';
  static const String taskListOverdue = '/task-list/overdue';
  static const String taskListStatistics = '/task-list/statistics';

  static String taskListById(String id) => '/task-list/$id';
  static String taskListToggle(String id) => '/task-list/$id/toggle';
  static String taskListComplete(String id) => '/task-list/$id/complete';
  static String taskListByUser(String userId) => '/task-list/user/$userId';
}
