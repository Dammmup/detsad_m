import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/shifts_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/api_constants.dart';
import '../../models/user_model.dart';

class StaffScheduleScreen extends StatefulWidget {
  const StaffScheduleScreen({super.key});

  @override
  State<StaffScheduleScreen> createState() => _StaffScheduleScreenState();
}

class _StaffScheduleScreenState extends State<StaffScheduleScreen> {
  DateTime _currentMonth = DateTime.now();
  final ShiftsService _shiftsService = ShiftsService();
  List<dynamic> _shifts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru_RU');
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user != null) {
        String startDate = DateFormat('yyyy-MM-01').format(_currentMonth);
        String endDate = DateFormat('yyyy-MM-dd').format(DateTime(_currentMonth.year, _currentMonth.month + 1, 0));

        final results = await Future.wait([
          _shiftsService.getStaffShifts(staffId: user.id, startDate: startDate, endDate: endDate),
          _shiftsService.getStaffAttendanceTrackingRecords(staffId: user.id, startDate: startDate, endDate: endDate),
        ]);

        if (mounted) {
          setState(() {
            _shifts = _combineShiftAndAttendanceData(results[0], results[1]);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() { _error = 'Пользователь не авторизован'; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Ошибка загрузки графика: $e'; _isLoading = false; });
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset);
    });
    _loadSchedule();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Мой график', style: AppTypography.titleLarge.copyWith(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: AppDecorations.pageBackground,
        child: Column(
          children: [
            const SizedBox(height: 100),
            _buildMonthSelector(),
            const SizedBox(height: AppSpacing.md),
            _buildUserInfo(user),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorPlaceholder()
                      : _shifts.isEmpty
                          ? _buildEmptyPlaceholder()
                          : _buildShiftsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: AppDecorations.cardElevated1,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Symbols.chevron_left_rounded, color: AppColors.primary)),
          Text(
            DateFormat('MMMM yyyy', 'ru_RU').format(_currentMonth).toUpperCase(),
            style: AppTypography.labelLarge.copyWith(color: AppColors.primary90, letterSpacing: 1.2),
          ),
          IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Symbols.chevron_right_rounded, color: AppColors.primary)),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildUserInfo(User? user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.cardElevated1,
      child: Row(
        children: [
          _buildStaffAvatar(user),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user?.firstName ?? ''} ${user?.lastName ?? ''}', style: AppTypography.titleMedium),
                Text('Роль: ${user?.role ?? ''}', style: AppTypography.bodySmall.copyWith(color: AppColors.grey500)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildShiftsList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
      itemCount: _shifts.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final shift = _shifts[index];
        final shiftDate = DateTime.parse(shift['date'].toString());
        final isToday = DateUtils.isSameDay(shiftDate, DateTime.now());

        return Container(
          decoration: isToday ? AppDecorations.cardElevated2.copyWith(border: Border.all(color: AppColors.primary30)) : AppDecorations.cardElevated1,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd MMMM, EEEE', 'ru_RU').format(shiftDate), style: AppTypography.labelLarge.copyWith(color: isToday ? AppColors.primary : AppColors.textPrimary)),
                    _buildStatusBadge(shift['status'] ?? 'scheduled'),
                  ],
                ),
                const Divider(height: 24),
                _buildTimeRow(Symbols.calendar_today_rounded, 'План:', '${shift['startTime']} - ${shift['endTime']}', isStrikethrough: shift['actualStartTime'] != null),
                if (shift['actualStartTime'] != null) ...[
                  const SizedBox(height: 8),
                  _buildTimeRow(Symbols.check_circle_rounded, 'Факт:', '${shift['actualStartTime']} - ${shift['actualEndTime'] ?? '...'}', color: AppColors.success),
                ],
                if (shift['notes']?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Symbols.notes_rounded, size: 14, color: AppColors.grey400),
                      const SizedBox(width: 8),
                      Expanded(child: Text(shift['notes'], style: AppTypography.bodySmall.copyWith(fontStyle: FontStyle.italic, color: AppColors.grey600))),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
      },
    );
  }

  Widget _buildTimeRow(IconData icon, String label, String value, {Color? color, bool isStrikethrough = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.grey400),
        const SizedBox(width: 8),
        Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.grey500)),
        const SizedBox(width: 4),
        Text(value, style: AppTypography.labelMedium.copyWith(color: color, decoration: isStrikethrough ? TextDecoration.lineThrough : null)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(_getStatusText(status), style: AppTypography.labelSmall.copyWith(color: color, fontSize: 10)),
    );
  }

  Widget _buildStaffAvatar(User? user) {
    String? avatarUrl = user?.avatar;
    if (avatarUrl?.isNotEmpty == true && !avatarUrl!.startsWith('http')) {
      avatarUrl = '${ApiConstants.baseUrl.replaceAll(RegExp(r'/$'), '')}/$avatarUrl';
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primary10,
      backgroundImage: avatarUrl?.isNotEmpty == true ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl?.isNotEmpty == true ? null : Text(user?.firstName.substring(0, 1).toUpperCase() ?? '?', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
    );
  }

  // Same logic as original
  List<dynamic> _combineShiftAndAttendanceData(List<dynamic> scheduledShifts, List<dynamic> attendanceRecords) {
    Map<String, dynamic> attendanceMap = {};
    for (var record in attendanceRecords) {
      String dateStr = DateTime.parse(record['date'].toString()).toIso8601String().split('T')[0];
      attendanceMap[dateStr] = record;
    }
    List<dynamic> combinedShifts = [];
    for (var shift in scheduledShifts) {
      String shiftDateStr = DateTime.parse(shift['date'].toString()).toIso8601String().split('T')[0];
      if (attendanceMap.containsKey(shiftDateStr)) {
        var attendance = attendanceMap[shiftDateStr];
        var combined = Map<String, dynamic>.from(shift);
        combined['actualStartTime'] = _formatISOToTimeString(attendance['actualStart']);
        combined['actualEndTime'] = _formatISOToTimeString(attendance['actualEnd']);
        combined['notes'] = attendance['notes'] ?? shift['notes'];
        combinedShifts.add(combined);
      } else {
        combinedShifts.add(shift);
      }
    }
    combinedShifts.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
    return combinedShifts;
  }

  String? _formatISOToTimeString(dynamic iso) {
    if (iso == null) return null;
    try {
      return DateFormat('HH:mm').format(DateTime.parse(iso.toString()));
    } catch (_) { return iso.toString(); }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'scheduled': return 'Запланирована';
      case 'in_progress': return 'В процессе';
      case 'completed': return 'Завершена';
      case 'late': return 'Опоздание';
      case 'vacation': return 'Отпуск';
      case 'sick_leave': return 'Болезнь';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled': return AppColors.info;
      case 'in_progress': return AppColors.warning;
      case 'completed': return AppColors.success;
      case 'late': return AppColors.error;
      case 'vacation': return Colors.orange;
      case 'sick_leave': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  Widget _buildEmptyPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Symbols.event_busy_rounded, size: 64, color: AppColors.grey300),
          const SizedBox(height: 16),
          Text('Нет запланированных смен', style: AppTypography.bodyLarge.copyWith(color: AppColors.grey500)),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Symbols.error_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: AppTypography.bodyMedium.copyWith(color: AppColors.error)),
            const SizedBox(height: 16),
            TextButton(onPressed: _loadSchedule, child: const Text('Попробовать снова')),
          ],
        ),
      ),
    );
  }
}
