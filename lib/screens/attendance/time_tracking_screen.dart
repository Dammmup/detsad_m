import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

import '../../core/services/shifts_service.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../models/user_model.dart';

class TimeTrackingScreen extends StatefulWidget {
  const TimeTrackingScreen({super.key});

  @override
  State<TimeTrackingScreen> createState() => _TimeTrackingScreenState();
}

class _TimeTrackingScreenState extends State<TimeTrackingScreen> {
  final ShiftsService _shiftsService = ShiftsService();
  final ApiService _apiService = ApiService();

  DateTime _currentMonth = DateTime.now();
  List<dynamic> _records = [];
  List<dynamic> _filteredRecords = [];
  List<User> _users = [];
  User? _selectedUser;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru_RU');
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final startDate = DateFormat('yyyy-MM-01').format(_currentMonth);
      final endDate = DateFormat('yyyy-MM-dd')
          .format(DateTime(_currentMonth.year, _currentMonth.month + 1, 0));

      final results = await Future.wait([
        _apiService.get(ApiConstants.users),
        _shiftsService.getStaffAttendanceTrackingRecords(
            startDate: startDate, endDate: endDate)
      ]);

      final dynamic usersResponse = results[0];
      final List<dynamic> recordsResult = results[1] as List<dynamic>;

      if (usersResponse.data != null && usersResponse.data is List) {
        _users = (usersResponse.data as List)
            .map((u) => User.fromJson(u))
            .toList();
      }

      if (mounted) {
        setState(() {
          _records = recordsResult;
          _isLoading = false;
        });
        _filterRecords();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки данных: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _filterRecords() {
    setState(() {
      if (_selectedUser == null) {
        _filteredRecords = List.from(_records);
      } else {
        _filteredRecords = _records.where((record) {
          final staffId = _getStaffIdFromRecord(record);
          return staffId == _selectedUser!.id;
        }).toList();
      }
      
      _filteredRecords.sort((a, b) {
        final dateA = DateTime.parse(a['date'].toString());
        final dateB = DateTime.parse(b['date'].toString());
        return dateB.compareTo(dateA);
      });
    });
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset);
    });
    _loadData();
  }

  String _getStaffIdFromRecord(dynamic record) {
    if (record['staffId'] is Map) {
      return record['staffId']['_id'] ?? record['staffId']['id'] ?? '';
    }
    return record['staffId']?.toString() ?? '';
  }

  User? _getUserForRecord(dynamic record) {
    final staffId = _getStaffIdFromRecord(record);
    try {
      return _users.firstWhere((u) => u.id == staffId);
    } catch (_) {
      return null;
    }
  }

  bool _isAdmin() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    return ['admin', 'manager'].contains(user?.role);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Учет рабочего времени',
            style: AppTypography.titleLarge.copyWith(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showBulkCorrectionDialog,
              backgroundColor: AppColors.warning,
              icon: const Icon(Symbols.swap_horiz_rounded, color: Colors.white),
              label: Text('Корректировка', style: AppTypography.labelMedium.copyWith(color: Colors.white)),
            )
          : null,
      body: Container(
        height: double.infinity,
        decoration: AppDecorations.pageBackground,
        child: Column(
          children: [
            const SizedBox(height: 100),
            _buildMonthSelector(),
            if (!_isLoading && _users.isNotEmpty) _buildUserFilter(),
            if (!_isLoading && _error == null) _buildSummaryCards(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildErrorState()
                      : _filteredRecords.isEmpty
                          ? _buildEmptyState()
                          : _buildRecordsList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBulkCorrectionDialog() async {
    String? selectedStatus;
    final Set<String> selectedStaffIds = {};
    String timeStart = '';
    String timeEnd = '';
    
    final startDate = DateFormat('yyyy-MM-01').format(_currentMonth);
    final endDate = DateFormat('yyyy-MM-dd').format(DateTime(_currentMonth.year, _currentMonth.month + 1, 0));

    const statuses = [
      {'value': 'scheduled', 'label': 'Запланирована'},
      {'value': 'completed', 'label': 'Завершена'},
      {'value': 'in_progress', 'label': 'Пришел'},
      {'value': 'late', 'label': 'Опоздание'},
      {'value': 'absent', 'label': 'Отсутствует'},
      {'value': 'vacation', 'label': 'Отпуск'},
      {'value': 'sick_leave', 'label': 'Больничный'},
    ];

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
                  Expanded(child: Text('Массовая корректировка', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900))),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Период: ${DateFormat('MMMM yyyy', 'ru_RU').format(_currentMonth)}', style: AppTypography.bodySmall.copyWith(color: AppColors.grey500)),
                      const SizedBox(height: AppSpacing.md),
                      
                      Text('Сотрудники:', style: AppTypography.labelMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey200),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final u = _users[index];
                            if (!u.active) return const SizedBox.shrink();
                            final isChecked = selectedStaffIds.contains(u.id);
                            return CheckboxListTile(
                              value: isChecked,
                              dense: true,
                              title: Text(u.fullName, style: AppTypography.bodySmall),
                              onChanged: (val) => setDialogState(() {
                                if (val == true) { selectedStaffIds.add(u.id); } else { selectedStaffIds.remove(u.id); }
                              }),
                              activeColor: AppColors.warning,
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      DropdownButtonFormField<String?>(
                        value: selectedStatus,
                        decoration: AppDecorations.inputDecoration(labelText: 'Изменить статус на'),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('Не менять статус')),
                          ...statuses.map((s) => DropdownMenuItem(value: s['value'], child: Text(s['label']!))),
                        ],
                        onChanged: (val) => setDialogState(() => selectedStatus = val),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: AppDecorations.inputDecoration(labelText: 'Время прихода', hintText: '09:00'),
                              keyboardType: TextInputType.datetime,
                              onChanged: (val) => timeStart = val,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextFormField(
                              decoration: AppDecorations.inputDecoration(labelText: 'Время ухода', hintText: '18:00'),
                              keyboardType: TextInputType.datetime,
                              onChanged: (val) => timeEnd = val,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx, false),
                  child: Text('Отмена', style: AppTypography.labelLarge.copyWith(color: AppColors.textTertiary)),
                ),
                ElevatedButton(
                  onPressed: (selectedStaffIds.isEmpty && selectedStatus == null && timeStart.isEmpty && timeEnd.isEmpty) 
                      ? null 
                      : () => Navigator.pop(dialogCtx, true),
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
        
        // Собрать ID записей для обновления
        final List<String> idsToUpdate = [];
        for (var record in _records) {
          final staffId = _getStaffIdFromRecord(record);
          if (selectedStaffIds.isEmpty || selectedStaffIds.contains(staffId)) {
            final id = record['_id']?.toString() ?? record['id']?.toString();
            if (id != null) idsToUpdate.add(id);
          }
        }

        if (idsToUpdate.isEmpty) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Нет записей для обновления')));
          setState(() => _isLoading = false);
          return;
        }

        await _shiftsService.bulkUpdateAttendanceRecords(
          ids: idsToUpdate,
          status: selectedStatus,
          timeStart: timeStart,
          timeEnd: timeEnd,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Обновлено ${idsToUpdate.length} записей'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ));
        }
        await _loadData();
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ));
        }
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
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Symbols.chevron_left_rounded, color: AppColors.primary),
          ),
          Text(
            DateFormat('MMMM yyyy', 'ru_RU').format(_currentMonth).toUpperCase(),
            style: AppTypography.labelLarge.copyWith(color: AppColors.primary90, letterSpacing: 1.2),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Symbols.chevron_right_rounded, color: AppColors.primary),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildUserFilter() {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md, left: AppSpacing.lg, right: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: AppDecorations.cardElevated1,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<User?>(
          isExpanded: true,
          value: _selectedUser,
          hint: Text('Все сотрудники', style: AppTypography.bodyMedium),
          icon: const Icon(Symbols.expand_more_rounded, color: AppColors.primary),
          items: [
            const DropdownMenuItem<User?>(
              value: null,
              child: Text('Все сотрудники'),
            ),
            ..._users.map((user) {
              return DropdownMenuItem<User?>(
                value: user,
                child: Text(user.fullName),
              );
            }),
          ],
          onChanged: (User? newValue) {
            setState(() {
              _selectedUser = newValue;
            });
            _filterRecords();
          },
        ),
      ),
    ).animate().fadeIn(delay: 50.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildSummaryCards() {
    int totalMinutes = 0;
    int lateMinutes = 0;

    for (var record in _filteredRecords) {
      if (record['workDurationMinutes'] != null) {
        totalMinutes += int.parse(record['workDurationMinutes'].toString());
      }
      if (record['lateMinutes'] != null) {
        lateMinutes += int.parse(record['lateMinutes'].toString());
      }
    }

    final totalHours = totalMinutes / 60;
    final lateHours = lateMinutes / 60;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: AppDecorations.cardElevated2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Отработано', style: AppTypography.labelMedium.copyWith(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(totalHours.toStringAsFixed(1), style: AppTypography.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text('ч', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: AppDecorations.cardElevated1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Опоздания', style: AppTypography.labelMedium.copyWith(color: AppColors.error)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(lateHours.toStringAsFixed(1), style: AppTypography.headlineMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Text('ч', style: AppTypography.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildRecordsList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
        itemCount: _filteredRecords.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final record = _filteredRecords[index];
          return _buildRecordCard(record, index);
        },
      ),
    );
  }

  Widget _buildRecordCard(dynamic record, int index) {
    final user = _getUserForRecord(record);
    final date = DateTime.parse(record['date'].toString());
    
    final startTime = _formatIsoTime(record['actualStart']);
    final endTime = _formatIsoTime(record['actualEnd']);
    
    final workMinutes = record['workDurationMinutes'] ?? 0;
    final workHoursStr = (workMinutes / 60).toStringAsFixed(1);
    
    final bool isLate = (record['lateMinutes'] ?? 0) > 0;
    
    return Container(
      decoration: AppDecorations.cardElevated1,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM, EEEE', 'ru_RU').format(date),
                style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
              ),
              _buildStatusBadge(record['status'] ?? 'unknown', isLate),
            ],
          ),
          const Divider(height: 24),
          if (user != null) ...[
            Row(
              children: [
                _buildAvatar(user, radius: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user.fullName,
                    style: AppTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeColumn('Приход', startTime, Icons.login_rounded, isLate ? AppColors.error : AppColors.success),
              _buildTimeColumn('Уход', endTime, Icons.logout_rounded, AppColors.grey600),
              _buildTimeColumn('Итог', '$workHoursStr ч', Icons.timer_rounded, AppColors.primary),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildTimeColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.grey400),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.grey500)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.titleMedium.copyWith(color: color)),
      ],
    );
  }

  Widget _buildStatusBadge(String status, bool isLate) {
    Color bColor = AppColors.success;
    String text = 'Ок';
    
    if (status == 'absent') {
      bColor = AppColors.error;
      text = 'Отсутствует';
    } else if (isLate) {
      bColor = AppColors.warning;
      text = 'Опоздание';
    } else if (status != 'present' && status != 'unknown') {
      bColor = AppColors.grey500;
      text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: bColor.withValues(alpha: 0.2)),
      ),
      child: Text(text, style: AppTypography.labelSmall.copyWith(color: bColor, fontSize: 10)),
    );
  }

  Widget _buildAvatar(User user, {double radius = 24}) {
    String? avatarUrl = user.avatar;
    if (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('http')) {
      avatarUrl = '${ApiConstants.baseUrl.replaceAll(RegExp(r'/$'), '')}/$avatarUrl';
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary10,
      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
          ? NetworkImage(avatarUrl)
          : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Text(
              user.firstName.isNotEmpty ? user.firstName.substring(0, 1).toUpperCase() : '?',
              style: AppTypography.labelLarge.copyWith(color: AppColors.primary, fontSize: radius * 0.8),
            )
          : null,
    );
  }

  String _formatIsoTime(dynamic iso) {
    if (iso == null) return '--:--';
    try {
      return DateFormat('HH:mm').format(DateTime.parse(iso.toString()).toLocal());
    } catch (_) {
      return '--:--';
    }
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, __) => const SkeletonCard(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Symbols.error_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Произошла ошибка',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Попробовать снова'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Symbols.event_busy_rounded, size: 64, color: AppColors.grey300),
          const SizedBox(height: 16),
          Text(
            'Нет данных за выбранный месяц',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.grey500),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}
