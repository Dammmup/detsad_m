import 'package:flutter/material.dart';
import '../../pages/login_page.dart';
import '../../pages/home_page.dart';
import '../../pages/mark_attendance_page.dart';
import '../../pages/view_attendance_all_page.dart';
import '../../pages/view_attendance_stud_page.dart';
import '../../pages/forgot_password_page.dart';
import '../../screens/documents/documents_list_screen.dart';
import '../../screens/children/children_list_screen.dart';
import '../../pages/map_view_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/mark-attendance':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => MarkAttendance(
                  code: args['code'],
                  uid: args['uid'],
                  students: args['students'],
                ));
      case '/view-attendance-all':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => ViewAttendanceAll(
                  code: args['code'],
                  uid: args['uid'],
                  students: args['students'],
                ));
      case '/view-attendance-stud':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
            builder: (_) => ViewAttendanceStud(
                  code: args['code'],
                  uid: args['uid'],
                ));
      case '/forgot-password':
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
      case '/children':
        return MaterialPageRoute(builder: (_) => const ChildrenListScreen());
      case '/documents':
        return MaterialPageRoute(builder: (_) => const DocumentsListScreen());
      case '/map':
        return MaterialPageRoute(builder: (_) => const MapViewPage());
      default:
        return MaterialPageRoute(builder: (_) => const HomePage());
    }
  }
}