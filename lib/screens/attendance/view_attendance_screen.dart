import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/children_provider.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_press.dart';
import '../../../models/attendance_record_model.dart';
import '../../../core/services/attendance_service.dart';

class ViewAttendanceScreen extends StatefulWidget {
  const ViewAttendanceScreen({super.key});

  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  List<AttendanceRecord> attendanceRecords = [];
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();
  final AttendanceService _attendanceService = AttendanceService();
  String _searchQuery = '';
  String? _selectedGroupId;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    try {
      setState(() => isLoading = true);
      String date = DateFormat('yyyy-MM-dd').format(selectedDate);
      final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
      if (childrenProvider.children.isEmpty) {
        await childrenProvider.loadChildren();
      }
      attendanceRecords = await _attendanceService.getAttendanceRecords(date, childrenProvider.children);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error));
      }
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
      _loadAttendance();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present': return AppColors.success;
      case 'absent': return AppColors.error;
      case 'late': return AppColors.warning;
      case 'early_departure': return Colors.blue;
      default: return AppColors.grey500;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'present': return 'Был';
      case 'absent': return 'Нет';
      case 'late': return 'Опоздал';
      case 'early_departure': return 'Ушел рано';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('История посещений', style: AppTypography.titleLarge.copyWith(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
      ),
      body: Container(
        decoration: AppDecorations.pageBackground,
        child: Column(
          children: [
            const SizedBox(height: 100),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _buildFilters(),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _getFilteredRecords().isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          itemCount: _getFilteredRecords().length,
                          itemBuilder: (context, index) => _buildAttendanceCard(_getFilteredRecords()[index]),
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final childrenProvider = Provider.of<ChildrenProvider>(context);
    
    // Получаем уникальные группы из списка детей
    final List<Map<String, String>> uniqueGroups = [];
    final Set<String> groupIds = {};

    for (var child in childrenProvider.children) {
      if (child.groupId != null && !groupIds.contains(child.groupId)) {
        groupIds.add(child.groupId!);
        uniqueGroups.add({
          'id': child.groupId!,
          'name': child.groupName ?? 'Без названия',
        });
      }
    }

    return Container(
      decoration: AppDecorations.cardElevated1,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          _buildDatePickerCard(),
          const SizedBox(height: AppSpacing.md),
          TextField(
            decoration: AppDecorations.searchInputDecoration(hintText: 'Поиск по имени...'),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary10,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedGroupId,
                      hint: const Text('Все группы'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Все группы')),
                        ...uniqueGroups.map((g) => DropdownMenuItem(value: g['id'], child: Text(g['name']!))),
                      ],
                      onChanged: (val) => setState(() => _selectedGroupId = val),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary10,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedStatus,
                      hint: const Text('Все статусы'),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Все статусы')),
                        DropdownMenuItem(value: 'present', child: Text('Был')),
                        DropdownMenuItem(value: 'absent', child: Text('Нет')),
                        DropdownMenuItem(value: 'late', child: Text('Опоздал')),
                        DropdownMenuItem(value: 'early_departure', child: Text('Ушел рано')),
                      ],
                      onChanged: (val) => setState(() => _selectedStatus = val),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<AttendanceRecord> _getFilteredRecords() {
    return attendanceRecords.where((record) {
      final matchesSearch = record.child.fullName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      String? recordGroupId;
      if (record.child.groupId is String) {
        recordGroupId = record.child.groupId as String;
      } else if (record.child.groupId is Map) {
        recordGroupId = (record.child.groupId as Map)['_id'] ?? (record.child.groupId as Map)['id'];
      }

      final matchesGroup = _selectedGroupId == null || recordGroupId == _selectedGroupId;
      final matchesStatus = _selectedStatus == null || record.status == _selectedStatus;
      
      return matchesSearch && matchesGroup && matchesStatus;
    }).toList();
  }

  Widget _buildDatePickerCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Выбранная дата', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
        const SizedBox(height: AppSpacing.sm),
        AnimatedPress(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.primary10, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(
              children: [
                const Icon(Symbols.calendar_month_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(DateFormat('dd MMMM yyyy', 'ru').format(selectedDate), style: AppTypography.labelLarge),
                const Spacer(),
                const Icon(Symbols.expand_more_rounded, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Symbols.event_busy_rounded, size: 64, color: AppColors.grey300),
          const SizedBox(height: AppSpacing.md),
          Text('Нет записей на эту дату', style: AppTypography.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    String childGroup = record.child.groupId is Map
        ? (record.child.groupId as Map)['name'] ?? 'Без группы'
        : 'Без группы';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: AppDecorations.cardElevated1,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: AppColors.primary10, shape: BoxShape.circle),
              child: Center(child: Text(record.child.fullName[0].toUpperCase(), style: AppTypography.titleMedium.copyWith(color: AppColors.primary))),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.child.fullName, style: AppTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(childGroup, style: AppTypography.bodySmall),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _getStatusColor(record.status).withAlpha(30), borderRadius: BorderRadius.circular(AppRadius.full)),
              child: Text(_getStatusText(record.status), style: AppTypography.bodySmall.copyWith(color: _getStatusColor(record.status), fontWeight: FontWeight.bold, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }
}
