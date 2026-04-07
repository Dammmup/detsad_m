import 'package:flutter/material.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../pages/forgot_password_page.dart';
import '../../screens/documents/documents_list_screen.dart';
import '../../screens/children/children_list_screen.dart';
import '../../pages/map_view_page.dart';
import '../../screens/staff/staff_profile_screen.dart';
import '../../screens/staff/staff_schedule_screen.dart';
import '../../screens/medical/medical_check_screen.dart';
import '../../screens/kitchen/kitchen_menu_screen.dart';
import '../../screens/attendance/mark_attendance_screen.dart';
import '../../screens/attendance/view_attendance_screen.dart';
import '../../screens/salary/salary_screen.dart';
import '../../screens/children/add_child_screen.dart';
import '../../screens/birthdays/birthdays_screen.dart';
import '../../screens/staff/staff_list_screen.dart';
import '../../screens/attendance/time_tracking_screen.dart';
import '../../screens/accounting/payments_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/home':
      case '/':
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case '/medical-check':
        return MaterialPageRoute(builder: (_) => const MedicalCheckScreen());
      case '/kitchen-menu':
        return MaterialPageRoute(builder: (_) => const KitchenMenuScreen());
      case '/mark-attendance':
        return MaterialPageRoute(builder: (_) => const MarkAttendanceScreen());
      case '/view-attendance-all':
        return MaterialPageRoute(builder: (_) => const ViewAttendanceScreen());
      case '/forgot-password':
        return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
      case '/children':
        return MaterialPageRoute(builder: (_) => const ChildrenListScreen());
      case '/documents':
        return MaterialPageRoute(builder: (_) => const DocumentsListScreen());
      case '/map':
        return MaterialPageRoute(builder: (_) => const MapViewPage());
      case '/staff-profile':
        return MaterialPageRoute(builder: (_) => const StaffProfileScreen());
      case '/staff-schedule':
        return MaterialPageRoute(builder: (_) => const StaffScheduleScreen());
      case '/salary':
        return MaterialPageRoute(builder: (_) => const SalaryScreen());
      case '/add-child':
        return MaterialPageRoute(builder: (_) => const AddChildScreen());
      case '/birthdays':
        return MaterialPageRoute(builder: (_) => const BirthdaysScreen());
      case '/staff-list':
        return MaterialPageRoute(builder: (_) => const StaffListScreen());
      case '/time-tracking':
        return MaterialPageRoute(builder: (_) => const TimeTrackingScreen());
      case '/payments':
        return MaterialPageRoute(builder: (_) => const PaymentsScreen());
      default:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
    }
  }
}
