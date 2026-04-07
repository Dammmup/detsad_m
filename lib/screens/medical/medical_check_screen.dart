import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/children_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/child_model.dart';
import '../../models/medical_record.dart';
import '../../core/services/medical_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/api_constants.dart';
import '../../core/widgets/animated_press.dart';

import 'dart:ui';
import '../../core/widgets/shimmer_loading.dart';

class MedicalCheckScreen extends StatefulWidget {
  final String? groupId;
  final String? groupName;

  const MedicalCheckScreen({
    super.key,
    this.groupId,
    this.groupName,
  });

  @override
  State<MedicalCheckScreen> createState() => _MedicalCheckScreenState();
}

class _MedicalCheckScreenState extends State<MedicalCheckScreen> {
  final MedicalService _medicalService = MedicalService();
  final Map<String, MedicalRecord?> _todayRecords = {};
  bool _isLoadingRecords = true;
  String _searchQuery = '';
  String? _selectedGroupId;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadTodayRecords();
  }

  Future<void> _loadTodayRecords() async {
    setState(() => _isLoadingRecords = true);
    try {
      final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
      if (childrenProvider.children.isEmpty) {
        await childrenProvider.loadChildren();
      }

      final records = await _medicalService.getTodayRecordsForDate(DateTime.now());
      
      if (mounted) {
        setState(() {
          _todayRecords.clear();
          for (var record in records) {
            _todayRecords[record.childId] = record;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading medical records: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRecords = false);
    }
  }

  List<Child> _getFilteredChildren(List<Child> children) {
    return children.where((c) {
      final matchesSearch = c.fullName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesGroup = _selectedGroupId == null || c.groupId == _selectedGroupId;
      
      final record = _todayRecords[c.id];
      final currentStatus = record?.status ?? 'healthy';
      final matchesStatus = _selectedStatus == null || currentStatus == _selectedStatus;
      
      return matchesSearch && matchesGroup && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: Text(
                widget.groupName != null ? 'Группа: ${widget.groupName}' : 'Утренний фильтр', 
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
                  icon: const Icon(Symbols.refresh_rounded, color: AppColors.primary90), 
                  onPressed: _loadTodayRecords
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: _buildFilters(),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
            Expanded(
              child: Consumer<ChildrenProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading || _isLoadingRecords) {
                    return _buildSkeletonLoading();
                  }

                  final filteredChildren = _getFilteredChildren(widget.groupId != null 
                      ? provider.children.where((c) => c.groupId == widget.groupId).toList()
                      : provider.children);

                  if (filteredChildren.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
                    itemCount: filteredChildren.length,
                    itemBuilder: (context, index) {
                      final childObj = filteredChildren[index];
                      final record = _todayRecords[childObj.id];
                      return _buildChildMedicalCard(childObj, record, index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final childrenProvider = Provider.of<ChildrenProvider>(context);
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

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5)
              )
            ]
          ),
          child: TextField(
            style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            decoration: AppDecorations.inputDecoration(
              hintText: 'Поиск по фамилии или имени...',
              prefixIcon: const Icon(Symbols.search_rounded, color: AppColors.primary, size: 22),
            ).copyWith(
              fillColor: AppColors.surface,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
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
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedStatus,
                    hint: const Text('Все статусы'),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Все статусы')),
                      DropdownMenuItem(value: 'healthy', child: Text('Здоров')),
                      DropdownMenuItem(value: 'observation', child: Text('Наблюдение')),
                      DropdownMenuItem(value: 'sick', child: Text('Болен')),
                    ],
                    onChanged: (val) => setState(() => _selectedStatus = val),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: 8,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: SkeletonLoader(width: double.infinity, height: 80, borderRadius: AppRadius.lg),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle
            ),
            child: const Icon(Symbols.person_search_rounded, size: 48, color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Никого не нашли', style: AppTypography.titleSmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Text('Попробуйте другой поисковый запрос', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildChildMedicalCard(Child child, MedicalRecord? record, int index) {
    bool isChecked = record != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: AppDecorations.cardElevated1.copyWith(
        color: isChecked ? AppColors.success.withValues(alpha: 0.02) : AppColors.surface,
        border: isChecked 
            ? Border.all(color: AppColors.success.withValues(alpha: 0.15), width: 1.5)
            : null,
      ),
      child: AnimatedPress(
        onTap: () => _showMedicalForm(child, record),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Hero(
                tag: 'child-avatar-${child.id}',
                child: _buildChildAvatar(child)
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.fullName, 
                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary)
                    ),
                    const SizedBox(height: 6),
                    if (isChecked) 
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTempColor(record.temperature).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6)
                            ),
                            child: Row(
                              children: [
                                Icon(Symbols.thermostat_rounded, size: 14, color: _getTempColor(record.temperature)),
                                const SizedBox(width: 2),
                                Text(
                                  '${record.temperature}°C', 
                                  style: AppTypography.bodySmall.copyWith(
                                    color: _getTempColor(record.temperature), 
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12
                                  )
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          _buildStatusBadge(record.status ?? 'healthy'),
                        ],
                      )
                    else 
                      Row(
                        children: [
                          const Icon(Symbols.schedule_rounded, size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            'Требуется осмотр', 
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500)
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (isChecked ? AppColors.primary : AppColors.surfaceVariant).withValues(alpha: 0.1),
                  shape: BoxShape.circle
                ),
                child: Icon(
                  isChecked ? Symbols.edit_rounded : Symbols.chevron_right_rounded,
                  color: isChecked ? AppColors.primary : AppColors.textTertiary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildChildAvatar(Child child) {
    String? photoUrl = child.photo;
    if (photoUrl != null && photoUrl.isNotEmpty && !photoUrl.startsWith('http')) {
      photoUrl = '${ApiConstants.baseUrl.replaceAll(RegExp(r'/$'), '')}/$photoUrl';
    }

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2)
          )
        ],
        image: photoUrl != null && photoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
      ),
      child: photoUrl == null || photoUrl.isEmpty
          ? Center(
              child: Text(
                child.fullName[0].toUpperCase(), 
                style: AppTypography.titleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900)
              )
            )
          : null,
    );
  }

  Color _getTempColor(double temp) {
    if (temp >= 37.3) return AppColors.error;
    if (temp >= 37.0) return AppColors.warning;
    return AppColors.success;
  }

  Widget _buildStatusBadge(String status) {
    String text = 'Здоров';
    Color color = AppColors.success;
    if (status == 'sick') {
      text = 'Болен';
      color = AppColors.error;
    } else if (status == 'observation') {
      text = 'Наблюдение';
      color = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text, 
        style: AppTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w800, fontSize: 10)
      ),
    );
  }

  void _showMedicalForm(Child child, MedicalRecord? existingRecord) {
    final TextEditingController tempController = TextEditingController(text: existingRecord?.temperature.toString() ?? '36.6');
    final TextEditingController notesController = TextEditingController(text: existingRecord?.notes ?? '');
    
    bool hasCough = existingRecord?.hasCough ?? false;
    bool hasRunnyNose = existingRecord?.hasRunnyNose ?? false;
    bool hasSoreThroat = existingRecord?.hasSoreThroat ?? false;
    String status = existingRecord?.status ?? 'healthy';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, -5)
                )
              ]
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildChildAvatar(child),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(child.fullName, style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900)),
                            Text('Группа: ${child.groupName ?? "—"}', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text('ОСНОВНЫЕ ПОКАЗАТЕЛИ', style: AppTypography.labelSmall.copyWith(color: AppColors.primary, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: tempController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTypography.titleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                    decoration: AppDecorations.inputDecoration(
                      labelText: 'Температура тела', 
                      prefixIcon: const Icon(Symbols.thermostat_rounded, color: AppColors.primary),
                      suffixIcon: const Padding(padding: EdgeInsets.all(16), child: Text('°C', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('СИМПТОМЫ', style: AppTypography.labelSmall.copyWith(color: AppColors.primary, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  _buildCheckbox(Symbols.coronavirus_rounded, 'Выраженный кашель', hasCough, (v) => setModalState(() => hasCough = v)),
                  _buildCheckbox(Symbols.water_drop_rounded, 'Насморк (ринит)', hasRunnyNose, (v) => setModalState(() => hasRunnyNose = v)),
                  _buildCheckbox(Symbols.sick_rounded, 'Боль в горле', hasSoreThroat, (v) => setModalState(() => hasSoreThroat = v)),
                  const SizedBox(height: 32),
                  Text('ЗАКЛЮЧЕНИЕ', style: AppTypography.labelSmall.copyWith(color: AppColors.primary, letterSpacing: 1.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: AppDecorations.inputDecoration(labelText: 'Статус допуска'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: status,
                        isExpanded: true,
                        style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(value: 'healthy', child: Text('✅ Здоров/Здорова')),
                          DropdownMenuItem(value: 'observation', child: Text('⚠️ Наблюдение')),
                          DropdownMenuItem(value: 'sick', child: Text('❌ Отстранен(а) по болезни')),
                        ],
                        onChanged: (val) => setModalState(() => status = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: AppDecorations.inputDecoration(
                      labelText: 'Дополнительные заметки', 
                      hintText: 'Жалобы или рекомендации...'
                    ),
                  ),
                  const SizedBox(height: 32),
                   const SizedBox(height: 32),
                  if (existingRecord != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteRecord(child.id, existingRecord.id),
                        icon: const Icon(Symbols.delete_rounded, color: AppColors.error),
                        label: Text('УДАЛИТЬ ЗАПИСЬ', style: AppTypography.labelLarge.copyWith(color: AppColors.error, fontWeight: FontWeight.w900)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: AnimatedPress(
                      onTap: () => _saveRecord(child.id, tempController.text, hasCough, hasRunnyNose, hasSoreThroat, status, notesController.text, existingRecord?.id),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6)
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            existingRecord != null ? 'ОБНОВИТЬ РЕЗУЛЬТАТ' : 'СОХРАНИТЬ РЕЗУЛЬТАТ', 
                            style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w900)
                          )
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildCheckbox(IconData icon, String label, bool value, Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (value ? AppColors.primary : AppColors.surfaceVariant).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)
              ),
              child: Icon(icon, size: 20, color: value ? AppColors.primary : AppColors.textTertiary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label, 
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: value ? FontWeight.w800 : FontWeight.w500,
                  color: value ? AppColors.textPrimary : AppColors.textSecondary
                )
              )
            ),
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v!),
              activeColor: AppColors.primary,
              side: const BorderSide(color: AppColors.surfaceVariant, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRecord(String childId, String tempStr, bool cough, bool runnyNose, bool soreThroat, String status, String notes, String? existingId) async {
    final double? temp = double.tryParse(tempStr.replaceAll(',', '.'));
    if (temp == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите корректную температуру'), backgroundColor: Colors.red));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final staffId = authProvider.user?.id;

    final record = MedicalRecord(
      id: existingId ?? '',
      childId: childId,
      date: DateTime.now(),
      temperature: temp,
      hasCough: cough,
      hasRunnyNose: runnyNose,
      hasSoreThroat: soreThroat,
      notes: notes,
      staffId: staffId,
      status: status,
    );

    try {
      MedicalRecord savedRecord;
      if (existingId != null) {
        savedRecord = await _medicalService.updateMedicalRecord(existingId, record);
      } else {
        savedRecord = await _medicalService.createMedicalRecord(record);
      }
      
      if (!mounted) return;
      setState(() => _todayRecords[childId] = savedRecord);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(existingId != null ? 'Запись обновлена' : 'Осмотр сохранен'), 
        backgroundColor: Colors.green
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteRecord(String childId, String recordId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление записи'),
        content: const Text('Вы уверены, что хотите удалить запись об осмотре?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ОТМЕНА')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('УДАЛИТЬ', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _medicalService.deleteMedicalRecord(recordId);
      if (!mounted) return;
      setState(() => _todayRecords.remove(childId));
      Navigator.pop(context); // Close sheet
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Запись удалена'), backgroundColor: Colors.blue));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка при удалении: $e'), backgroundColor: Colors.red));
    }
  }
}
