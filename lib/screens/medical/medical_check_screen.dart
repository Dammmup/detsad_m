import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/children_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/child_model.dart';
import '../../models/medical_record.dart';
import '../../core/services/medical_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';

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

      final children = widget.groupId != null
          ? childrenProvider.children.where((c) => c.groupId == widget.groupId).toList()
          : childrenProvider.children;

      for (var child in children) {
        final record = await _medicalService.getTodayRecord(child.id);
        _todayRecords[child.id] = record;
      }
    } catch (e) {
      AppLogger.error('MedicalCheckScreen | Error loading records: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingRecords = false);
      }
    }
  }

  List<Child> _getFilteredChildren(List<Child> children) {
    if (_searchQuery.isEmpty) return children;
    return children
        .where((c) => c.fullName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName != null ? 'Фильтр: ${widget.groupName}' : 'Утренний фильтр'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Container(
        decoration: AppDecorations.pageBackground,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: AppDecorations.searchInputDecoration(
                  hintText: 'Поиск ребенка...',
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Expanded(
              child: Consumer<ChildrenProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading || _isLoadingRecords) {
                    return const Center(child: CircularProgressIndicator());
                  }

                   final allChildren = provider.children;
                   final filteredByGroup = widget.groupId != null 
                       ? allChildren.where((c) => c.groupId == widget.groupId).toList()
                       : allChildren;
                   final filteredChildren = _getFilteredChildren(filteredByGroup);

                  if (filteredChildren.isEmpty) {
                    return const Center(child: Text('Дети не найдены'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredChildren.length,
                    itemBuilder: (context, index) {
                      final childObj = filteredChildren[index];
                      final record = _todayRecords[childObj.id];
                      return _buildChildMedicalCard(childObj, record);
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

  Widget _buildChildMedicalCard(Child child, MedicalRecord? record) {
    bool isChecked = record != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecorations.cardDecoration.copyWith(
        border: isChecked 
          ? Border.all(color: AppColors.success.withValues(alpha: 0.5), width: 1)
          : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _buildChildAvatar(child),
        title: Text(
          child.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isChecked) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.thermostat, size: 14, color: _getTempColor(record.temperature)),
                  Text(
                    ' ${record.temperature}°C',
                    style: TextStyle(
                      color: _getTempColor(record.temperature),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(record.status ?? 'healthy'),
                ],
              ),
            ] else 
              const Text('Осмотр не пройден', style: TextStyle(color: Colors.grey)),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            isChecked ? Icons.edit : Icons.add_circle_outline,
            color: isChecked ? AppColors.primary : AppColors.textSecondary,
          ),
          onPressed: () => _showMedicalForm(child, record),
        ),
      ),
    );
  }

  Widget _buildChildAvatar(Child child) {
    String? photoUrl = child.photo;
    if (photoUrl != null && photoUrl.isNotEmpty && !photoUrl.startsWith('http')) {
      photoUrl = '${ApiConstants.baseUrl.replaceAll(RegExp(r'/$'), '')}/$photoUrl';
    }

    return CircleAvatar(
      radius: 25,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
      child: photoUrl == null || photoUrl.isEmpty
          ? Text(child.fullName[0].toUpperCase(), style: const TextStyle(color: AppColors.primary))
          : null,
    );
  }

  Color _getTempColor(double temp) {
    if (temp >= 37.2) return Colors.red;
    if (temp >= 37.0) return Colors.orange;
    return Colors.green;
  }

  Widget _buildStatusBadge(String status) {
    String text = 'Здоров';
    Color color = Colors.green;
    if (status == 'sick') {
      text = 'Болен';
      color = Colors.red;
    } else if (status == 'observation') {
      text = 'Наблюдение';
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showMedicalForm(Child child, MedicalRecord? existingRecord) {
    final TextEditingController tempController = TextEditingController(
      text: existingRecord?.temperature.toString() ?? '36.6',
    );
    final TextEditingController notesController = TextEditingController(
      text: existingRecord?.notes ?? '',
    );
    
    bool hasCough = existingRecord?.hasCough ?? false;
    bool hasRunnyNose = existingRecord?.hasRunnyNose ?? false;
    bool hasSoreThroat = existingRecord?.hasSoreThroat ?? false;
    String status = existingRecord?.status ?? 'healthy';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildChildAvatar(child),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            child.fullName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    const Text('Температура', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: tempController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(suffixText: '°C'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Симптомы', style: TextStyle(fontWeight: FontWeight.bold)),
                    CheckboxListTile(
                      title: const Text('Кашель'),
                      value: hasCough,
                      onChanged: (val) => setModalState(() => hasCough = val!),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Насшморк'),
                      value: hasRunnyNose,
                      onChanged: (val) => setModalState(() => hasRunnyNose = val!),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Больное горло'),
                      value: hasSoreThroat,
                      onChanged: (val) => setModalState(() => hasSoreThroat = val!),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                    const Text('Статус', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: status,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'healthy', child: Text('Здоров')),
                        DropdownMenuItem(value: 'sick', child: Text('Болен')),
                        DropdownMenuItem(value: 'observation', child: Text('Наблюдение')),
                      ],
                      onChanged: (val) => setModalState(() => status = val!),
                    ),
                    const SizedBox(height: 16),
                    const Text('Заметки', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'Добавьте комментарий...'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _saveRecord(
                          child.id,
                          tempController.text,
                          hasCough,
                          hasRunnyNose,
                          hasSoreThroat,
                          status,
                          notesController.text,
                        ),
                        child: const Text('Сохранить осмотр'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Future<void> _saveRecord(
    String childId,
    String tempStr,
    bool cough,
    bool runnyNose,
    bool soreThroat,
    String status,
    String notes,
  ) async {
    final double? temp = double.tryParse(tempStr);
    if (temp == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректную температуру')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final staffId = authProvider.user?.id;

    final record = MedicalRecord(
      id: '', // Will be assigned by backend
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
      final savedRecord = await _medicalService.createMedicalRecord(record);
      if (!mounted) return;
      setState(() {
        _todayRecords[childId] = savedRecord;
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Данные осмотра сохранены')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении: $e')),
      );
    }
  }
}
