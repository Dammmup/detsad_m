import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/child_model.dart';
import '../../../core/services/children_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/groups_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_press.dart';

class AddChildScreen extends StatefulWidget {
  final Child? child;
  const AddChildScreen({super.key, this.child});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _childrenService = ChildrenService();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _iinController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();

  String? _selectedGroupId;
  String? _selectedGender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.child != null) {
      _fullNameController.text = widget.child!.fullName;
      _iinController.text = widget.child!.iin ?? '';
      _birthdayController.text = widget.child!.birthday ?? '';
      _parentNameController.text = widget.child!.parentName ?? '';
      _parentPhoneController.text = widget.child!.parentPhone ?? '';
      _selectedGroupId = widget.child!.groupId is String ? widget.child!.groupId as String : (widget.child!.groupId is Map ? (widget.child!.groupId as Map)['_id'] ?? (widget.child!.groupId as Map)['id'] : null);
      _selectedGender = widget.child!.gender;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadGroups();
    });
  }

  Future<void> _loadGroups() async {
    final groupsProvider = context.read<GroupsProvider>();
    final currentUser = context.read<AuthProvider>().user;

    bool isTeacherOrSubstitute = currentUser != null && (currentUser.role == 'teacher' || currentUser.role == 'substitute');

    if (isTeacherOrSubstitute) {
      await groupsProvider.loadGroupsByTeacherId(currentUser.id);
    } else {
      await groupsProvider.loadGroups();
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary, 
              onPrimary: Colors.white, 
              onSurface: AppColors.textPrimary
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthdayController.text = picked.toIso8601String().split('T')[0]);
    }
  }

  Future<void> _saveChild() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final currentUser = context.read<AuthProvider>().user;

      final childData = Child(
        id: widget.child?.id ?? '',
        fullName: _fullNameController.text.trim(),
        iin: _iinController.text.trim().isEmpty ? null : _iinController.text.trim(),
        birthday: _birthdayController.text.isEmpty ? null : _birthdayController.text,
        parentName: _parentNameController.text.trim().isEmpty ? null : _parentNameController.text.trim(),
        parentPhone: _parentPhoneController.text.trim().isEmpty ? null : _parentPhoneController.text.trim(),
        groupId: _selectedGroupId,
        staffId: widget.child?.staffId ?? currentUser?.id,
        gender: _selectedGender,
        active: widget.child?.active ?? true,
      );

      if (widget.child != null) {
        await _childrenService.updateChild(widget.child!.id, childData);
      } else {
        await _childrenService.createChild(childData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.child != null ? 'Данные ребенка обновлены' : 'Ребенок успешно добавлен'), 
            backgroundColor: AppColors.success, 
            behavior: SnackBarBehavior.floating
          )
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                widget.child != null ? 'Редактирование' : 'Новый ребенок', 
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
            ),
          ),
        ),
      ),
      body: Container(
        decoration: AppDecorations.pageBackground,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 110),
                _buildFormSection('Основная информация', [
                  TextFormField(
                    controller: _fullNameController,
                    style: AppTypography.bodyMedium,
                    decoration: AppDecorations.inputDecoration(
                      labelText: 'ФИО ребенка', 
                      prefixIcon: const Icon(Symbols.person_rounded, size: 20)
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Введите ФИО' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _iinController,
                    style: AppTypography.bodyMedium,
                    decoration: AppDecorations.inputDecoration(
                      labelText: 'ИИН', 
                      prefixIcon: const Icon(Symbols.fingerprint_rounded, size: 20)
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _birthdayController,
                          readOnly: true,
                          style: AppTypography.bodyMedium,
                          decoration: AppDecorations.inputDecoration(
                            labelText: 'Дата рождения', 
                            prefixIcon: const Icon(Symbols.cake_rounded, size: 20)
                          ),
                          onTap: _selectDate,
                          validator: (v) => v == null || v.isEmpty ? 'Выберите дату' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedGender,
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                          decoration: AppDecorations.inputDecoration(
                            labelText: 'Пол', 
                            prefixIcon: const Icon(Symbols.wc_rounded, size: 20)
                          ),
                          items: const ['Мужской', 'Женский'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (v) => setState(() => _selectedGender = v),
                        ),
                      ),
                    ],
                  ),
                ], index: 0),
                const SizedBox(height: AppSpacing.lg),
                _buildFormSection('Группа', [
                  Consumer<GroupsProvider>(
                    builder: (context, groupsProvider, child) {
                      if (groupsProvider.isLoading) {
                        return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)));
                      }
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedGroupId,
                        isExpanded: true,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                        decoration: AppDecorations.inputDecoration(
                          labelText: 'Выберите группу', 
                          prefixIcon: const Icon(Symbols.groups_rounded, size: 20)
                        ),
                        items: groupsProvider.groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setState(() => _selectedGroupId = v),
                      );
                    },
                  ),
                ], index: 1),
                const SizedBox(height: AppSpacing.lg),
                _buildFormSection('Контактные данные', [
                  TextFormField(
                    controller: _parentNameController,
                    style: AppTypography.bodyMedium,
                    decoration: AppDecorations.inputDecoration(
                      labelText: 'ФИО родителя', 
                      prefixIcon: const Icon(Symbols.supervisor_account_rounded, size: 20)
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _parentPhoneController,
                    style: AppTypography.bodyMedium,
                    keyboardType: TextInputType.phone,
                    decoration: AppDecorations.inputDecoration(
                      labelText: 'Телефон родителя', 
                      prefixIcon: const Icon(Symbols.phone_enabled_rounded, size: 20)
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _addressController,
                    style: AppTypography.bodyMedium,
                    maxLines: 2,
                    decoration: AppDecorations.inputDecoration(
                      labelText: 'Адрес проживания', 
                      prefixIcon: const Icon(Symbols.home_rounded, size: 20)
                    ),
                  ),
                ], index: 2),
                const SizedBox(height: AppSpacing.xxl),
                _buildSubmitButton(),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection(String title, List<Widget> children, {required int index}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(title, style: AppTypography.labelLarge.copyWith(color: AppColors.primary90, fontWeight: FontWeight.bold)),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: AppDecorations.cardElevated1,
          child: Column(children: children),
        ),
      ],
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSubmitButton() {
    return AnimatedPress(
      onTap: _isLoading ? null : _saveChild,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient, 
          borderRadius: BorderRadius.circular(AppRadius.lg), 
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3), 
              blurRadius: 12, 
              offset: const Offset(0, 4)
            )
          ]
        ),
        child: Center(
          child: _isLoading 
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                widget.child != null ? 'Сохранить изменения' : 'Зарегистрировать ребенка', 
                style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w900)
              ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _iinController.dispose();
    _birthdayController.dispose();
    _addressController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    super.dispose();
  }
}
