import 'package:flutter/material.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/attendance/mark_attendance_screen.dart';
import '../../screens/attendance/view_attendance_screen.dart';
import '../../screens/documents/documents_list_screen.dart';
import '../../screens/children/children_list_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case '/mark-attendance':
        return MaterialPageRoute(builder: (_) => const MarkAttendanceScreen());
      case '/view-attendance':
        return MaterialPageRoute(builder: (_) => const ViewAttendanceScreen());
      case '/children':
        return MaterialPageRoute(builder: (_) => const ChildrenListScreen());
      case '/documents':
        return MaterialPageRoute(builder: (_) => const DocumentsListScreen());
      default:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
    }
  }
}