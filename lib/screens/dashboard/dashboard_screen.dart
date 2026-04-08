import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../providers/auth_provider.dart';
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
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/animated_press.dart';
import '../../core/widgets/user_avatar.dart';
import '../staff/staff_profile_screen.dart';
import '../staff/staff_schedule_screen.dart';
import '../salary/salary_screen.dart';
import '../../../providers/groups_provider.dart';
import '../../../models/group_model.dart';
import '../medical/medical_check_screen.dart';
import '../kitchen/kitchen_menu_screen.dart';
import '../staff/staff_list_screen.dart';
import '../attendance/time_tracking_screen.dart';
import '../accounting/payments_screen.dart';

import 'dart:ui';

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
        Provider.of<GeolocationProvider>(context, listen: false).loadSettings();
        Provider.of<GroupsProvider>(context, listen: false).loadGroups();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final role = user?.role ?? '';
    
    bool isAdmin = role == 'admin';
    bool isStaff = user != null && !isAdmin;
    bool canManageChildren = user != null && ['teacher', 'assistant', 'substitute', 'admin', 'manager', 'nurse', 'cook'].contains(role);

    return StaffShiftStatusManager(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AppBar(
                title: Text(
                  'Главная',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                elevation: 0,
                centerTitle: false,
                actions: [
                  IconButton(
                    icon: const Icon(Symbols.logout_rounded, color: AppColors.textPrimary),
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
            ),
          ),
        ),
        body: Container(
          decoration: AppDecorations.pageBackground,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + AppSpacing.md),
                _buildWelcomeSection(user, isStaff),
                const SizedBox(height: AppSpacing.lg),
                
                const TasksWidget().animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
                const SizedBox(height: AppSpacing.lg),
                
                _buildGroupsSection(),
                const SizedBox(height: AppSpacing.lg),
                
                const GeolocationStatusWidget().animate().fadeIn(delay: 200.ms),
                const SizedBox(height: AppSpacing.lg),
                
                if (isStaff) ...[
                  _buildStaffAttendanceSection(),
                  const SizedBox(height: AppSpacing.lg),
                ],

                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Функции',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.primary90,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildActionGrid(canManageChildren, isStaff, user),
                const SizedBox(height: AppSpacing.lg),
                
                const BirthdaysWidget().animate().fadeIn(delay: 500.ms),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(dynamic user, bool isStaff) {
    return AnimatedPress(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const StaffProfileScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: AppDecorations.cardElevated3.copyWith(
          gradient: AppColors.primaryGradient,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Добрый день,',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim().isNotEmpty 
                      ? '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim()
                      : (user?.phone ?? 'Пользователь'),
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      user?.role?.toUpperCase() ?? 'USER',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            UserAvatar(
              avatar: user?.avatar,
              fullName: user?.fullName ?? '?',
              size: 64,
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(duration: 500.ms, curve: Curves.fastOutSlowIn);
  }

  Widget _buildGroupsSection() {
    return Consumer2<GroupsProvider, AuthProvider>(
      builder: (context, groupsProvider, authProvider, child) {
        if (groupsProvider.isLoading) return const SizedBox.shrink();

        final user = authProvider.user;
        final role = user?.role ?? '';

        // Фильтруем группы по роли пользователя
        List<Group> userGroups;
        if (role == 'admin' || role == 'manager') {
          userGroups = groupsProvider.groups;
        } else {
          userGroups = groupsProvider.groups.where((g) =>
            g.teacherId == user?.id || g.assistantId == user?.id
          ).toList();
        }

        if (userGroups.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Ваши группы',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppColors.primary90,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: userGroups.length,
                itemBuilder: (context, index) {
                  final group = userGroups[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: AnimatedPress(
                      onTap: () => _showGroupActionDialog(context, group),
                      child: Container(
                        width: 160,
                        decoration: AppDecorations.cardElevated2.copyWith(
                          color: AppColors.primaryContainer,
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -15,
                              bottom: -15,
                              child: Icon(
                                Symbols.groups_rounded, 
                                size: 80, 
                                color: AppColors.primary.withValues(alpha: 0.1),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    group.name,
                                    style: AppTypography.titleMedium.copyWith(
                                      color: AppColors.primary90,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${group.children?.length ?? 0} детей',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.primary.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStaffAttendanceSection() {
    return Container(
      decoration: AppDecorations.cardElevated1.copyWith(
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.1), width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Symbols.work_history_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Рабочая смена',
                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Смена на сегодня',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const SizedBox(width: 100, child: StaffAttendanceButton()),
        ],
      ),
    );
  }

  Widget _buildActionGrid(bool canManageChildren, bool isStaff, dynamic user) {
    final role = user?.role ?? '';
    bool isAdmin = role == 'admin';
    bool isManager = role == 'manager';
    bool isAccountant = role == 'buhgalter';
    
    bool canViewStaff = isAdmin || isManager;
    bool canManageAccounting = isAdmin || isAccountant || isManager;
    bool canViewTimeTracking = isAdmin || isManager;

    final actions = [
      if (canManageChildren || isAdmin) _DashboardAction('Утренний осмотр', Symbols.medical_services_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalCheckScreen()))),
      if (canManageChildren || isAdmin) _DashboardAction('Отметить детей', Symbols.child_care_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarkAttendanceScreen()))),
      _DashboardAction('Посещаемость', Symbols.calendar_month_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewAttendanceScreen()))),
      _DashboardAction('Меню кухни', Symbols.restaurant_menu_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KitchenMenuScreen()))),
      _DashboardAction('Список детей', Symbols.group_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildrenListScreen()))),
      if (canManageChildren || isAdmin) _DashboardAction('Новый ребенок', Symbols.person_add_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddChildScreen()))),
      if (isStaff) _DashboardAction('Мой график', Symbols.event_note_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffScheduleScreen()))),
      if (user?.allowToSeePayroll == true || isAdmin) _DashboardAction('Зарплаты', Symbols.account_balance_wallet_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalaryScreen()))),
      if (canViewStaff) _DashboardAction('Сотрудники', Symbols.badge_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffListScreen()))),
      if (canViewTimeTracking) _DashboardAction('Учет времени', Symbols.schedule_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimeTrackingScreen()))),
      if (canManageAccounting) _DashboardAction('Оплаты', Symbols.payments_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsScreen()))),
      _DashboardAction('Дни рождения', Symbols.cake_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BirthdaysScreen()))),
    ];

    return MasonryGridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return AnimatedPress(
          onTap: action.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.md),
            decoration: AppDecorations.cardElevated1.copyWith(
              color: AppColors.surface,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(action.icon, size: 28, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  action.title,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (300 + index * 40).ms).scale(begin: const Offset(0.95, 0.95));
      },
    );
  }

  void _showGroupActionDialog(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(group.name, style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogButton(context, 'Утренний осмотр', Symbols.medical_services_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MedicalCheckScreen(groupId: group.id, groupName: group.name)))),
            const SizedBox(height: AppSpacing.md),
            _buildDialogButton(context, 'Отметить посещаемость', Symbols.child_care_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarkAttendanceScreen()))),
            const SizedBox(height: AppSpacing.md),
            _buildDialogButton(context, 'История / Отчеты', Symbols.history_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewAttendanceScreen()))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Закрыть', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogButton(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return AnimatedPress(
      onTap: () { Navigator.pop(context); onTap(); },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title, 
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary90,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Symbols.chevron_right_rounded, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _DashboardAction {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  _DashboardAction(this.title, this.icon, this.onTap);
}
