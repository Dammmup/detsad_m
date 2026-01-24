import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/utils/logger.dart';
import 'providers/auth_provider.dart';
import 'providers/children_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/shifts_provider.dart';
import 'providers/documents_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/groups_provider.dart';
import 'providers/task_provider.dart';
import 'providers/geolocation_provider.dart';
import 'providers/payroll_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'core/navigation/app_router.dart';
import 'pages/splash_screen_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await StorageService().init();

  await NotificationService().init();

  AppLogger.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChildrenProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => DocumentsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => GroupsProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => GeolocationProvider()),
        ChangeNotifierProvider(create: (_) => PayrollProvider()),
        ChangeNotifierProxyProvider<GeolocationProvider, ShiftsProvider>(
          create: (context) => ShiftsProvider(),
          update: (context, geoProvider, shiftsProvider) {
            if (shiftsProvider == null) return ShiftsProvider();
            shiftsProvider.setGeolocationProvider(geoProvider);
            return shiftsProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Attendance App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        onGenerateRoute: AppRouter.generateRoute,
        routes: {
          'login': (context) => const LoginScreen(),
          'home': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}
