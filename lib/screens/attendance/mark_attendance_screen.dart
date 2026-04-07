import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_press.dart';
import '../../../models/child_model.dart';
import '../../../models/attendance_model.dart';
import '../../../core/services/children_service.dart';
import '../../../core/services/attendance_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/groups_provider.dart';
import '../../../models/user_model.dart';
import 'package:provider/provider.dart';

import 'dart:ui';
import '../../../core/widgets/shimmer_loading.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  List<Child> children = [];
  Map<String, bool> _attendanceState = {};
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();
  String _searchQuery = '';
  String? _selectedGroupId;
  final ChildrenService _childrenService = ChildrenService();
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      setState(() => isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final User? currentUser = authProvider.user;
      final groupsProvider = Provider.of<GroupsProvider>(context, listen: false);

      await groupsProvider.loadGroups();
      final allGroups = groupsProvider.groups;

      List<Child> fetchedChildren;
      if (currentUser != null && ['teacher', 'assistant', 'substitute'].contains(currentUser.role)) {
        final teacherGroupIds = allGroups
            .where((g) => g.teacher == currentUser.id || g.teacherId == currentUser.id || g.assistantId == currentUser.id)
            .map((g) => g.id)
            .toList();
        
        if (teacherGroupIds.isNotEmpty) {
          fetchedChildren = await _childrenService.getChildrenByGroupIds(teacherGroupIds);
        } else {
          fetchedChildren = [];
        }
      } else {
        fetchedChildren = await _childrenService.getAllChildren();
      }

      String date = DateFormat('yyyy-MM-dd').format(selectedDate);
      List<Attendance> todaysAttendance = await _attendanceService.getAttendanceByDate(date);

      if (mounted) {
        setState(() {
          children = fetchedChildren;
          _attendanceState = {
            for (var child in children) 
              child.id: todaysAttendance.any((att) => (att.childId == child.id || att.userId == child.id) && att.status == 'present')
          };
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error));
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _markAttendance() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    try {
      setState(() => isLoading = true);
      String dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      List<Attendance> records = [];

      for (var child in children) {
        final isPresent = _attendanceState[child.id] ?? false;
        String childGroupId = '';
        if (child.groupId is String) {
          childGroupId = child.groupId as String;
        } else if (child.groupId is Map) {
          childGroupId = (child.groupId as Map)['_id']?.toString() ?? (child.groupId as Map)['id']?.toString() ?? '';
        }

        if (childGroupId.isEmpty) continue;
        records.add(Attendance(
          id: '',
          childId: child.id,
          groupId: childGroupId,
          date: dateStr,
          checkIn: isPresent ? DateFormat('HH:mm').format(DateTime.now()) : '',
          status: isPresent ? 'present' : 'absent',
          notes: 'Отметка от мобильного приложения',
        ));
      }

      if (records.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Список пуст')));
        setState(() => isLoading = false);
        return;
      }

      Map<String, List<Attendance>> groupedByGroup = {};
      for (var r in records) {
        groupedByGroup.putIfAbsent(r.groupId, () => []).add(r);
      }

      for (var entry in groupedByGroup.entries) {
        await _attendanceService.markAttendanceBulk(entry.value, groupId: entry.key);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Успешно сохранено'), backgroundColor: AppColors.success));
        await _loadChildren();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white, onSurface: AppColors.primary90),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      _loadChildren();
    }
  }

  @override
  Widget build(BuildContext context) {
    int presentCount = _attendanceState.values.where((p) => p == true).length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: Text(
                'Посещаемость', 
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primary90,
                  fontWeight: FontWeight.w900,
                )
              ),
              centerTitle: true,
              backgroundColor: AppColors.surface.withValues(alpha: 0.7),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Symbols.arrow_back_ios_new_rounded, color: AppColors.primary90, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Symbols.calendar_month_rounded, color: AppColors.primary90), 
                  onPressed: _selectDate
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: AppDecorations.pageBackground,
        child: Column(
          children: [
            const SizedBox(height: 110),
            _buildHeaderStats(presentCount),
            _buildFilters(),
            Expanded(
              child: isLoading
                  ? _buildSkeletonLoading()
                  : _getFilteredChildren().isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxxl),
                          itemCount: _getFilteredChildren().length,
                          itemBuilder: (context, index) => _buildChildListItem(_getFilteredChildren()[index]),
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
            ),
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStats(int presentCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: AppDecorations.cardElevated2.copyWith(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, dd MMMM', 'ru').format(selectedDate),
                    style: AppTypography.labelLarge.copyWith(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.normal)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Присутствуют: $presentCount из ${children.length}',
                    style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w900)
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16)
              ),
              child: const Icon(Symbols.people_rounded, color: Colors.white, size: 28),
            )
          ],
        ),
      ).animate().fadeIn().scale(delay: 100.ms),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: 8,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: SkeletonLoader(width: double.infinity, height: 74, borderRadius: AppRadius.lg),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Symbols.group_off_rounded, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.lg),
          Text(_searchQuery.isNotEmpty ? 'Никто не найден' : 'Нет детей в списке', style: AppTypography.titleSmall.copyWith(color: AppColors.textSecondary)),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildFilters() {
    final groupsProvider = Provider.of<GroupsProvider>(context);
    final user = Provider.of<AuthProvider>(context).user;
    
    final teacherGroups = groupsProvider.groups.where((g) => 
      g.teacherId == user?.id || g.assistantId == user?.id || user?.role == 'admin'
    ).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
           TextField(
            decoration: AppDecorations.searchInputDecoration(hintText: 'Поиск ребенка...'),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (teacherGroups.length > 1 || user?.role == 'admin')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1))
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedGroupId,
                  hint: const Text('Все группы'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Все группы')),
                    ...teacherGroups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))),
                  ],
                  onChanged: (val) => setState(() => _selectedGroupId = val),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  List<Child> _getFilteredChildren() {
    return children.where((child) {
      final matchesSearch = child.fullName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      String childGroupId = '';
      if (child.groupId is String) {
        childGroupId = child.groupId as String;
      } else if (child.groupId is Map) {
        childGroupId = (child.groupId as Map)['_id']?.toString() ?? (child.groupId as Map)['id']?.toString() ?? '';
      }
      
      final matchesGroup = _selectedGroupId == null || childGroupId == _selectedGroupId;
      return matchesSearch && matchesGroup;
    }).toList();
  }

  Widget _buildChildListItem(Child child) {
    final isPresent = _attendanceState[child.id] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: AppDecorations.cardElevated1.copyWith(
        border: isPresent 
            ? Border.all(color: AppColors.success.withValues(alpha: 0.15), width: 1.5)
            : null,
      ),
      child: InkWell(
        onTap: () => setState(() => _attendanceState[child.id] = !isPresent),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              _buildAvatar(child, isPresent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.fullName, 
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isPresent ? AppColors.textPrimary : AppColors.textSecondary
                      )
                    ),
                    Text(
                      child.groupName ?? 'Без группы', 
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isPresent ? AppColors.success : AppColors.surfaceVariant).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Icon(
                  isPresent ? Symbols.check_circle_rounded : Symbols.cancel_rounded,
                  color: isPresent ? AppColors.success : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Child child, bool isPresent) {
    String? photoUrl = child.photo;
    if (photoUrl != null && photoUrl.isNotEmpty && !photoUrl.startsWith('http')) {
      photoUrl = '${ApiConstants.baseUrl.replaceAll(RegExp(r'/$'), '')}/$photoUrl';
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(
          color: isPresent ? AppColors.success : Colors.white, 
          width: 2
        ),
        boxShadow: const [AppColors.shadowLevel1],
        image: photoUrl != null && photoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
      ),
      child: photoUrl == null || photoUrl.isEmpty
          ? Center(
              child: Text(
                child.fullName[0].toUpperCase(), 
                style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900)
              )
            )
          : null,
    );
  }

  Widget _buildBottomAction() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.8),
            border: const Border(top: BorderSide(color: AppColors.surfaceVariant, width: 0.5)),
          ),
          child: SafeArea(
            child: AnimatedPress(
              onTap: _markAttendance,
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient, 
                  borderRadius: BorderRadius.circular(AppRadius.md), 
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5)
                    )
                  ]
                ),
                child: Center(
                  child: Text(
                    'СОХРАНИТЬ ПОСЕЩАЕМОСТЬ', 
                    style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w900)
                  )
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
