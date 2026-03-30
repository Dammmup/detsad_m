import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/shifts_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/geolocation_provider.dart';
import '../attendance/mark_attendance_screen.dart';
import '../attendance/view_attendance_screen.dart';
import '../children/children_list_screen.dart';
import '../children/add_child_screen.dart';
import '../auth/login_screen.dart';
import '../birthdays/birthdays_screen.dart';
import '../../components/staff_attendance_button.dart';
import '../../components/staff_shift_status_manager.dart';
import '../../components/birthdays_widget.dart';
import '../../components/tasks_widget.dart';
import '../../components/geolocation_status_widget.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../staff/staff_profile_screen.dart';
import '../staff/staff_schedule_screen.dart';
import '../salary/salary_screen.dart';
import '../../../providers/groups_provider.dart';
import '../../../models/group_model.dart';
import '../medical/medical_check_screen.dart';
import '../kitchen/kitchen_menu_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final geoProvider =
            Provider.of<GeolocationProvider>(context, listen: false);
        geoProvider.loadSettings();

        // Загружаем группы при входе
        final groupsProvider = 
            Provider.of<GroupsProvider>(context, listen: false);
        groupsProvider.loadGroups();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final shiftsProvider = Provider.of<ShiftsProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final user = authProvider.user;

    bool isStaff = user != null && user.role != 'admin';
    bool canManageChildren = user != null &&
        (user.role == 'admin' ||
            user.role == 'teacher' ||
            user.role == 'assistant' ||
            user.role == 'substitute');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (!shiftsProvider.areNotificationsScheduled) {
          notificationProvider.scheduleDailyArrivalNotification(
              id: 1, time: Time(hour: 8, minute: 0));

          notificationProvider.scheduleDailyDepartureNotification(
              id: 2, time: Time(hour: 18, minute: 0));

          notificationProvider.scheduleDailyAttendanceNotification(
              id: 3, time: Time(hour: 9, minute: 0));

          shiftsProvider.setNotificationsScheduled();
        }
      }
    });

    return StaffShiftStatusManager(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Дашборд'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
          ],
        ),
        body: Container(
          decoration: AppDecorations.pageBackground,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppDecorations.cardDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Добро пожаловать,',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[60]),
                              ),
                              Text(
                                '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Роль: ${user?.role ?? ''}',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (isStaff)
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const StaffProfileScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: AppDecorations.cardDecoration,
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 32,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Мой профиль',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.grey600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const TasksWidget(),
                  const SizedBox(height: 24),
                  
                  // Секция групп
                  Consumer<GroupsProvider>(
                    builder: (context, groupsProvider, child) {
                      if (groupsProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (groupsProvider.groups.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ваши группы',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: groupsProvider.groups.length,
                              itemBuilder: (context, index) {
                                final group = groupsProvider.groups[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: GestureDetector(
                                    onTap: () => _showGroupActionDialog(context, group),
                                    child: Container(
                                      width: 160,
                                      decoration: AppDecorations.cardDecoration.copyWith(
                                        gradient: AppColors.primaryGradient,
                                      ),
                                      child: Center(
                                        child: Text(
                                          group.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const GeolocationStatusWidget(),
                  const SizedBox(height: 16),
                  if (isStaff) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: AppDecorations.cardDecoration,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Отметка посещения',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    'Отметьте ваш приход или уход',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: SizedBox(
                                child: StaffAttendanceButton(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      if (canManageChildren)
                        _buildDashboardCard(
                          context,
                          'Отметить детей',
                          Icons.child_care,
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MarkAttendanceScreen(),
                              ),
                            );
                          },
                        ),
                      _buildDashboardCard(
                        context,
                        'Посещаемость детей',
                        Icons.visibility,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ViewAttendanceScreen(),
                            ),
                          );
                        },
                      ),
                      _buildDashboardCard(
                        context,
                        'Список детей',
                        Icons.people,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ChildrenListScreen(),
                            ),
                          );
                        },
                      ),
                      if (canManageChildren)
                        _buildDashboardCard(
                          context,
                          'Добавить ребёнка',
                          Icons.add,
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AddChildScreen(),
                              ),
                            );
                          },
                        ),
                      if (isStaff)
                        _buildDashboardCard(
                          context,
                          'Мой график',
                          Icons.schedule,
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const StaffScheduleScreen(),
                              ),
                            );
                          },
                        ),
                      if (isStaff && user.allowToSeePayroll == true)
                        _buildDashboardCard(
                          context,
                          'Моя зарплата',
                          Icons.account_balance_wallet,
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SalaryScreen(),
                              ),
                            );
                          },
                        ),
                      _buildDashboardCard(
                        context,
                        'Дни рождения',
                        Icons.cake,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const BirthdaysScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const BirthdaysWidget(),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showGroupActionDialog(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group.name),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogButton(
              context,
              'Отметить посещаемость',
              Icons.check_circle_outline,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MarkAttendanceScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildDialogButton(
              context,
              'Посещаемость список',
              Icons.list_alt,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ViewAttendanceScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildDialogButton(
              context,
              'Утренний фильтр (Мед)',
              Icons.medical_services_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MedicalCheckScreen(
                    groupId: group.id,
                    groupName: group.name,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildDialogButton(
              context,
              'Меню кухни',
              Icons.restaurant_menu,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const KitchenMenuScreen(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogButton(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          onTap();
        },
        icon: Icon(icon, color: Colors.white),
        label: Text(title, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [AppColors.shadowHero],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
