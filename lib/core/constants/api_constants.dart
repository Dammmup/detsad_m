import 'package:flutter/foundation.dart';

class ApiConstants {
  // Base URL - измените на ваш реальный URL
  static String get baseUrl {
    // Для веб-версии используем localhost
    if (kIsWeb) {
      return 'http://192.168.0.66:8080';
    } else {
      // Для локальной разработки на мобильном устройстве используем localhost
      // Если вы тестируете на физическом устройстве, замените на IP-адрес компьютера
      return 'http://192.168.0.66:8080'; // Ваш IP-адрес
      // return 'http://10.0.2.2:8080'; // Для эмулятора Android
    }
  }
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String validateToken = '/auth/validate';
  static const String currentUser = '/auth/current-user';
  
  // Users endpoints
  static const String users = '/users';
  static String userById(String id) => '/users/$id';
  
  // Children endpoints
  static const String children = '/children';
  static String childById(String id) => '/children/$id';
  static String childrenByGroup(String groupId) => '/children/group/$groupId';
  
  // Groups endpoints
  static const String groups = '/groups';
  static String groupById(String id) => '/groups/$id';
  
  // Attendance endpoints
  static const String childAttendance = '/child-attendance';
  static const String childAttendanceBulk = '/child-attendance/bulk';
  static const String childAttendanceStats = '/child-attendance/stats';
  
  // Staff Attendance endpoints
  static const String clockIn = '/attendance/clock-in';
  static const String clockOut = '/attendance/clock-out';
  static const String breakStart = '/attendance/break-start';
  static const String breakEnd = '/attendance/break-end';
  static const String attendanceEntries = '/attendance/entries';
  static const String attendanceSummary = '/attendance/summary';
  
  // Staff Shifts endpoints
 static const String staffShifts = '/staff-shifts';
  static const String staffShiftsBulk = '/staff-shifts/bulk';
  static String staffShiftCheckin(String shiftId) => '/staff-shifts/checkin/$shiftId';
  static String staffShiftCheckout(String shiftId) => '/staff-shifts/checkout/$shiftId';
  
  // Schedule endpoints
  static const String schedule = '/schedule';
  static String scheduleByStaff(String staffId) => '/schedule/staff/$staffId';
  static String scheduleByGroup(String groupId) => '/schedule/group/$groupId';
  
  // Settings endpoints
  static const String settingsKindergarten = '/settings/kindergarten';
  static const String settingsGeolocation = '/settings/geolocation';
  
  // Main Events endpoints
  static const String mainEvents = '/main-events';
  static String mainEventById(String id) => '/main-events/$id';
  
  // Child Payments endpoints
  static const String childPayments = '/child-payments';
  static String childPaymentById(String id) => '/child-payments/$id';
  static String childPaymentsByPeriod(String period) => '/child-payments/period/$period';
  
  // Task List endpoints
  static const String taskList = '/task-list';
  static const String taskListOverdue = '/task-list/overdue';
  static const String taskListStatistics = '/task-list/statistics';
  
  // Task List methods
  static String taskListById(String id) => '/task-list/$id';
  static String taskListToggle(String id) => '/task-list/$id/toggle';
  static String taskListComplete(String id) => '/task-list/$id/complete';
  static String taskListByUser(String userId) => '/task-list/user/$userId';
}