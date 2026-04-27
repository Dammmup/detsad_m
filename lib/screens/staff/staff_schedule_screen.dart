import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/shifts_service.dart';
import '../../core/services/api_service.dart';
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
  final ApiService _apiService = ApiService();
  List<dynamic> _shifts = [];
  List<User> _allUsers = [];
  String? _selectedUserId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru_RU');
    _loadSchedule();
    if (_canEditShifts()) _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final response = await _apiService.get(ApiConstants.users);
      if (response.data != null && response.data is List && mounted) {
        setState(() {
          _allUsers = (response.data as List).map((u) => User.fromJson(u)).where((u) => u.active).toList();
        });
      }
    } catch (_) {}
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

        final bool isAdmin = ['admin', 'manager'].contains(user.role);
        final String? filterStaffId = isAdmin ? _selectedUserId : user.id;

        final List<Future<List<dynamic>>> futures = [
          isAdmin && filterStaffId == null
              ? _shiftsService.getAllStaffShifts(startDate: startDate, endDate: endDate)
              : _shiftsService.getStaffShifts(staffId: filterStaffId, startDate: startDate, endDate: endDate),
          _shiftsService.getStaffAttendanceTrackingRecords(staffId: filterStaffId, startDate: startDate, endDate: endDate),
        ];

        final results = await Future.wait(futures);

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
    final isAdmin = _canEditShifts();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isAdmin ? 'График смен' : 'Мой график', style: AppTypography.titleLarge.copyWith(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAdminActionsMenu(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Symbols.add_rounded, color: Colors.white),
              label: Text('Действия', style: AppTypography.labelMedium.copyWith(color: Colors.white)),
            )
          : null,
      body: Container(
        height: double.infinity,
        decoration: AppDecorations.pageBackground,
        child: Column(
          children: [
            const SizedBox(height: 100),
            _buildMonthSelector(),
            const SizedBox(height: AppSpacing.md),
            if (isAdmin && _allUsers.isNotEmpty) _buildUserFilter(),
            if (!isAdmin) _buildUserInfo(user),
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

  void _showAdminActionsMenu(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: AppSpacing.lg),
              Text('Действия администратора', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary10, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Symbols.calendar_month_rounded, color: AppColors.primary),
                ),
                title: Text('Назначить график 5/2', style: AppTypography.labelLarge),
                subtitle: Text('Массовое создание смен ПН-ПТ', style: AppTypography.bodySmall.copyWith(color: AppColors.grey500)),
                onTap: () { Navigator.pop(context); _showAssign52Dialog(); },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Symbols.swap_horiz_rounded, color: AppColors.warning),
                ),
                title: Text('Массовая корректировка статусов', style: AppTypography.labelLarge),
                subtitle: Text('Изменить статус смен за период', style: AppTypography.bodySmall.copyWith(color: AppColors.grey500)),
                onTap: () { Navigator.pop(context); _showBulkStatusDialog(); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserFilter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: AppDecorations.cardElevated1,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: _selectedUserId,
          hint: Text('Все сотрудники', style: AppTypography.bodyMedium),
          icon: const Icon(Symbols.expand_more_rounded, color: AppColors.primary),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Все сотрудники')),
            ..._allUsers.map((u) => DropdownMenuItem<String?>(value: u.id, child: Text(u.fullName))),
          ],
          onChanged: (val) {
            setState(() => _selectedUserId = val);
            _loadSchedule();
          },
        ),
      ),
    ).animate().fadeIn(delay: 50.ms).slideY(begin: -0.1, end: 0);
  }

  Future<void> _showAssign52Dialog() async {
    final Set<String> selectedStaff = {};
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              title: Row(
                children: [
                  const Icon(Symbols.calendar_month_rounded, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text('Назначить 5/2', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900))),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Месяц: ${DateFormat('MMMM yyyy', 'ru_RU').format(_currentMonth)}', style: AppTypography.bodySmall.copyWith(color: AppColors.grey500)),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Будут созданы смены на все рабочие дни (ПН-ПТ)', style: AppTypography.bodySmall.copyWith(color: AppColors.grey600)),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Выберите сотрудников:', style: AppTypography.labelMedium),
                        TextButton(
                          onPressed: () => setDialogState(() {
                            if (selectedStaff.length == _allUsers.length) { selectedStaff.clear(); } else { selectedStaff.addAll(_allUsers.map((u) => u.id)); }
                          }),
                          child: Text(selectedStaff.length == _allUsers.length ? 'Снять все' : 'Выбрать все', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 250,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _allUsers.length,
                        itemBuilder: (context, index) {
                          final u = _allUsers[index];
                          final isChecked = selectedStaff.contains(u.id);
                          return CheckboxListTile(
                            value: isChecked,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(u.fullName, style: AppTypography.labelMedium),
                            subtitle: Text(u.position ?? u.role, style: AppTypography.bodySmall.copyWith(color: AppColors.grey500, fontSize: 11)),
                            onChanged: (val) => setDialogState(() {
                              if (val == true) { selectedStaff.add(u.id); } else { selectedStaff.remove(u.id); }
                            }),
                            activeColor: AppColors.primary,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: Text('Отмена', style: AppTypography.labelLarge.copyWith(color: AppColors.textTertiary)),
                ),
                ElevatedButton(
                  onPressed: selectedStaff.isEmpty ? null : () => Navigator.pop(dialogCtx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
                  child: Text('Назначить (${selectedStaff.length})'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && selectedStaff.isNotEmpty) {
      await _executeAssign52(selectedStaff.toList());
    }
  }

  Future<void> _executeAssign52(List<String> staffIds) async {
    try {
      setState(() => _isLoading = true);
      final monthStart = DateTime(_currentMonth.year, _currentMonth.month, 1);
      final monthEnd = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

      // Получить существующие смены
      final existing = await _shiftsService.getAllStaffShifts(
        startDate: DateFormat('yyyy-MM-dd').format(monthStart),
        endDate: DateFormat('yyyy-MM-dd').format(monthEnd),
      );

      // Собрать Set существующих (staffId_date)
      final existingSet = <String>{};
      for (var s in existing) {
        final sid = s['staffId'] is Map ? (s['staffId']['_id'] ?? s['staffId']['id']) : s['staffId'];
        final date = DateTime.parse(s['date'].toString()).toIso8601String().split('T')[0];
        existingSet.add('${sid}_$date');
      }

      // Генерировать рабочие дни ПН-ПТ
      final shiftsToCreate = <Map<String, dynamic>>[];
      for (var staffId in staffIds) {
        var day = monthStart;
        while (!day.isAfter(monthEnd)) {
          if (day.weekday >= 1 && day.weekday <= 5) {
            final dateStr = DateFormat('yyyy-MM-dd').format(day);
            if (!existingSet.contains('${staffId}_$dateStr')) {
              final user = _allUsers.where((u) => u.id == staffId).firstOrNull;
              shiftsToCreate.add({
                'staffId': staffId,
                'staffName': user?.fullName ?? '',
                'date': dateStr,
                'status': 'scheduled',
                'notes': 'График 5/2',
              });
            }
          }
          day = day.add(const Duration(days: 1));
        }
      }

      if (shiftsToCreate.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Все смены уже назначены'), backgroundColor: AppColors.info));
        await _loadSchedule();
        return;
      }

      final result = await _shiftsService.bulkCreateShifts(shiftsToCreate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Создано ${result['success'] ?? shiftsToCreate.length} смен'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
        ));
      }
      await _loadSchedule();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _showBulkStatusDialog() async {
    String selectedStatus = 'completed';
    String? selectedStaffId;
    final startDate = DateFormat('yyyy-MM-01').format(_currentMonth);
    final endDate = DateFormat('yyyy-MM-dd').format(DateTime(_currentMonth.year, _currentMonth.month + 1, 0));

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              title: Row(
                children: [
                  const Icon(Symbols.swap_horiz_rounded, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text('Корректировка статусов', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Период: $startDate — $endDate', style: AppTypography.bodySmall.copyWith(color: AppColors.grey500)),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String?>(
                    value: selectedStaffId,
                    decoration: AppDecorations.inputDecoration(labelText: 'Сотрудник'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Все сотрудники')),
                      ..._allUsers.map((u) => DropdownMenuItem<String?>(value: u.id, child: Text(u.fullName))),
                    ],
                    onChanged: (val) => setDialogState(() => selectedStaffId = val),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: AppDecorations.inputDecoration(labelText: 'Новый статус'),
                    items: _editableStatuses.map((s) => DropdownMenuItem(value: s['value'], child: Text(s['label']!))).toList(),
                    onChanged: (val) => setDialogState(() => selectedStatus = val ?? 'completed'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: Text('Отмена', style: AppTypography.labelLarge.copyWith(color: AppColors.textTertiary)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogCtx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md))),
                  child: const Text('Обновить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      try {
        setState(() => _isLoading = true);
        await _shiftsService.bulkUpdateStatus(startDate: startDate, endDate: endDate, status: selectedStatus, staffId: selectedStaffId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Статусы обновлены на: ${_getStatusText(selectedStatus)}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
          ));
        }
        await _loadSchedule();
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error));
      }
    }
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

  // Доступные статусы для изменения (синхронизировано с фронтендом)
  static const List<Map<String, String>> _editableStatuses = [
    {'value': 'scheduled', 'label': 'Запланирована'},
    {'value': 'completed', 'label': 'Завершена'},
    {'value': 'in_progress', 'label': 'Пришел'},
    {'value': 'late', 'label': 'Опоздание'},
    {'value': 'absent', 'label': 'Отсутствует'},
    {'value': 'vacation', 'label': 'Отпуск'},
    {'value': 'sick_leave', 'label': 'Больничный'},
  ];

  bool _canEditShifts() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return false;
    return ['admin', 'manager'].contains(user.role);
  }

  Future<void> _showEditStatusDialog(Map<String, dynamic> shift) async {
    if (!_canEditShifts()) return;

    String? shiftId = shift['_id']?.toString() ?? shift['id']?.toString();
    String currentStatus = shift['status'] ?? 'scheduled';
    String? selectedStatus = currentStatus;

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              title: Row(
                children: [
                  const Icon(Symbols.edit_calendar_rounded, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Изменить статус', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Дата: ${shift['date'] is String ? DateFormat('dd MMMM yyyy', 'ru_RU').format(DateTime.parse(shift['date'])) : ''}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.grey500),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ..._editableStatuses.map((statusItem) {
                    final isSelected = selectedStatus == statusItem['value'];
                    return ListTile(
                      title: Text(
                        statusItem['label']!,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      leading: Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected ? AppColors.primary : AppColors.grey400,
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onTap: () => setDialogState(() => selectedStatus = statusItem['value']),
                    );
                  }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: Text('Отмена', style: AppTypography.labelLarge.copyWith(color: AppColors.textTertiary)),
                ),
                ElevatedButton(
                  onPressed: selectedStatus != currentStatus
                      ? () => Navigator.of(dialogContext).pop(selectedStatus)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && shiftId != null && result != currentStatus) {
      await _updateShiftStatus(shiftId, result);
    }
  }

  Future<void> _updateShiftStatus(String shiftId, String newStatus) async {
    try {
      setState(() => _isLoading = true);
      await _shiftsService.updateShift(shiftId, {'status': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Статус обновлён: ${_getStatusText(newStatus)}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      await _loadSchedule();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Widget _buildShiftsList() {
    final canEdit = _canEditShifts();
    final isShowingAll = canEdit && _selectedUserId == null;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
      itemCount: _shifts.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final shift = _shifts[index];
        final shiftDate = DateTime.parse(shift['date'].toString());
        final isToday = DateUtils.isSameDay(shiftDate, DateTime.now());

        // Получить имя сотрудника
        String? staffName;
        if (isShowingAll) {
          final staffId = shift['staffId'];
          if (staffId is Map) {
            staffName = staffId['fullName'] ?? '${staffId['firstName'] ?? ''} ${staffId['lastName'] ?? ''}'.trim();
          } else {
            staffName = shift['staffName']?.toString();
          }
        }

        Widget card = GestureDetector(
          onTap: canEdit ? () => _showEditStatusDialog(shift) : null,
          child: Container(
            decoration: isToday ? AppDecorations.cardElevated2.copyWith(border: Border.all(color: AppColors.primary30)) : AppDecorations.cardElevated1,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (staffName != null && staffName.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Symbols.person_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(child: Text(staffName, style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700))),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(DateFormat('dd MMMM, EEEE', 'ru_RU').format(shiftDate), style: AppTypography.labelLarge.copyWith(color: isToday ? AppColors.primary : AppColors.textPrimary)),
                          if (canEdit)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Symbols.edit_rounded, size: 14, color: AppColors.grey400),
                            ),
                        ],
                      ),
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
          ),
        );

        // Свайп для удаления (только admin/manager)
        if (canEdit) {
          final shiftId = shift['_id']?.toString() ?? shift['id']?.toString();
          card = Dismissible(
            key: Key(shiftId ?? 'shift_$index'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Удалить смену?'),
                  content: const Text('Это действие нельзя отменить'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Удалить', style: TextStyle(color: AppColors.error))),
                  ],
                ),
              ) ?? false;
            },
            onDismissed: (_) async {
              if (shiftId != null) {
                try {
                  await _shiftsService.deleteShift(shiftId);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Смена удалена'), backgroundColor: AppColors.info));
                  await _loadSchedule();
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error));
                }
              }
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: const Icon(Symbols.delete_rounded, color: AppColors.error),
            ),
            child: card,
          );
        }

        return card.animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
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

  // Синхронизированные с фронтендом названия статусов
  String _getStatusText(String status) {
    switch (status) {
      case 'scheduled': return 'Запланирована';
      case 'completed': return 'Завершена';
      case 'in_progress': return 'Пришел';
      case 'checked_in': return 'На работе';
      case 'on_work': return 'На работе';
      case 'checked_out': return 'Ушел';
      case 'late': return 'Опоздание';
      case 'late_arrival': return 'Поздний приход';
      case 'absent': return 'Отсутствует';
      case 'sick': return 'Больничный';
      case 'sick_leave': return 'Больничный';
      case 'vacation': return 'Отпуск';
      case 'no_clock_in': return 'Нет прихода';
      case 'no_clock_out': return 'Нет ухода';
      case 'pending_approval': return 'Ожидает подтверждения';
      case 'early_departure': return 'Ранний уход';
      case 'early_leave': return 'Ранний уход';
      default: return status;
    }
  }

  // Синхронизированные с фронтендом цвета статусов
  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled': return AppColors.info;
      case 'completed': return AppColors.success;
      case 'in_progress': return AppColors.warning;
      case 'checked_in': return AppColors.warning;
      case 'on_work': return AppColors.warning;
      case 'checked_out': return AppColors.error;
      case 'late': return AppColors.error;
      case 'late_arrival': return AppColors.warning;
      case 'absent': return AppColors.error;
      case 'sick': return Colors.purple;
      case 'sick_leave': return Colors.purple;
      case 'vacation': return Colors.teal;
      case 'no_clock_in': return Colors.amber;
      case 'no_clock_out': return Colors.amber;
      case 'pending_approval': return Colors.blueGrey;
      case 'early_departure': return AppColors.warning;
      case 'early_leave': return AppColors.warning;
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
