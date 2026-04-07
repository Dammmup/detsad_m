import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../models/payroll_model.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../providers/groups_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/animated_press.dart';

import 'dart:ui';
import '../../core/widgets/shimmer_loading.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'ru_RU', symbol: '₸', decimalDigits: 0);

  // Фильтры для админа
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedPosition;
  String? _selectedGroupId;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru', null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final isAdmin = auth.user?.role == 'admin';
      if (isAdmin) {
        context.read<PayrollProvider>().loadAllPayrolls();
        context.read<GroupsProvider>().loadGroups();
      } else {
        context.read<PayrollProvider>().loadMyPayroll();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Payroll> get _filteredPayrolls {
    final provider = context.read<PayrollProvider>();
    return provider.payrolls.where((p) {
      // Поиск по имени
      if (_searchQuery.isNotEmpty) {
        final name = p.staff?.fullName.toLowerCase() ?? '';
        if (!name.contains(_searchQuery.toLowerCase())) return false;
      }
      
      // Фильтр по должности
      if (_selectedPosition != null && p.staff?.position != _selectedPosition) {
        return false;
      }

      // Фильтр по группе
      if (_selectedGroupId != null) {
        final groupsProvider = context.read<GroupsProvider>();
        final isStaffInGroup = groupsProvider.groups.any((g) => 
          g.id == _selectedGroupId && (g.teacherId == p.staff?.id || g.assistantId == p.staff?.id)
        );
        if (!isStaffInGroup) return false;
      }

      // Фильтр по статусу
      if (_selectedStatus != null && p.status != _selectedStatus) {
        return false;
      }
      
      return true;
    }).toList();
  }

  Future<void> _onAddFine(Payroll p) async {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить штраф'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: AppDecorations.inputDecoration(labelText: 'Сумма'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              decoration: AppDecorations.inputDecoration(labelText: 'Причина'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ОТМЕНА')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ДОБАВИТЬ', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (result == true && amountController.text.isNotEmpty && p.id != null) {
      try {
        final amount = double.tryParse(amountController.text) ?? 0;
        if (!mounted) return;
        await context.read<PayrollProvider>().addFine(p.id!, amount, reasonController.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Штраф добавлен'), backgroundColor: AppColors.success));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error));
        }
      }
    }
  }

  Future<void> _onDeleteFine(Payroll p, String fineId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление штрафа'),
        content: const Text('Вы уверены, что хотите удалить этот штраф?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('НЕТ')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ДА', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );

    if (confirm == true && p.id != null) {
      try {
        if (!mounted) return;
        await context.read<PayrollProvider>().deleteFine(p.id!, fineId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Штраф удален'), backgroundColor: AppColors.info));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error));
        }
      }
    }
  }

  Future<void> _onUpdateStatus(Payroll p, String status) async {
    if (p.id == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Изменение статуса'),
        content: Text('Вы действительно хотите изменить статус на "${status == 'paid' ? 'Выплачено' : status}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ОТМЕНА')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ПОДТВЕРДИТЬ', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (!mounted) return;
      await context.read<PayrollProvider>().updateStatus(p.id!, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Статус обновлен'), backgroundColor: AppColors.success));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _onDeletePayroll(Payroll p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление зарплаты'),
        content: const Text('Вы уверены, что хотите удалить эту запись?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ОТМЕНА')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('УДАЛИТЬ', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );

    if (confirm == true && p.id != null) {
      try {
        if (!mounted) return;
        await context.read<PayrollProvider>().deletePayroll(p.id!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Запись удалена'), backgroundColor: AppColors.info));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error));
        }
      }
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
              title: Consumer<PayrollProvider>(
                builder: (context, provider, _) {
                  final auth = context.read<AuthProvider>();
                  final isAdmin = auth.user?.role == 'admin';
                  String titleText = 'Моя зарплата';
                  if (isAdmin) {
                    titleText = provider.currentPayroll == null ? 'Зарплаты' : 'Зарплата';
                  }
                  return Text(
                    titleText, 
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary90,
                      fontWeight: FontWeight.w900,
                    )
                  );
                }
              ),
              centerTitle: true,
              backgroundColor: AppColors.surface.withValues(alpha: 0.7),
              elevation: 0,
              leading: Consumer<PayrollProvider>(
                builder: (context, provider, _) {
                  final auth = context.read<AuthProvider>();
                  final isAdmin = auth.user?.role == 'admin';
                  if (isAdmin && provider.currentPayroll != null) {
                    return IconButton(
                      icon: const Icon(Symbols.arrow_back_ios_new_rounded, color: AppColors.primary90, size: 20),
                      onPressed: () => provider.clearSelection(),
                    );
                  }
                  return IconButton(
                    icon: const Icon(Symbols.arrow_back_ios_new_rounded, color: AppColors.primary90, size: 20),
                    onPressed: () => Navigator.pop(context),
                  );
                }
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: AppDecorations.pageBackground,
        child: Consumer<PayrollProvider>(
          builder: (context, provider, child) {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final isAdmin = authProvider.user?.role == 'admin';
            
            if (authProvider.user?.allowToSeePayroll == false && !isAdmin) {
              return _buildNoAccess();
            }

            if (provider.isLoading) {
              return _buildSkeletonLoading();
            }

            if (provider.errorMessage != null) {
              return _buildErrorState(provider);
            }

            return RefreshIndicator(
              onRefresh: () => isAdmin ? provider.loadAllPayrolls() : provider.loadMyPayroll(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    const SizedBox(height: 110),
                    _buildMonthSelector(provider),
                    const SizedBox(height: AppSpacing.lg),
                    if (isAdmin && provider.currentPayroll == null)
                      _buildAdminListView(provider)
                    else if (provider.currentPayroll == null)
                      _buildEmptyState()
                    else ...[
                      if (isAdmin) ...[
                        _buildUserProfileCard(provider.currentPayroll!),
                        _buildAdminActions(provider.currentPayroll!),
                      ],
                      _buildTotalCard(provider, provider.currentPayroll!.total),
                      const SizedBox(height: AppSpacing.lg),
                      _buildDetailsGrid(provider),
                      const SizedBox(height: AppSpacing.lg),
                      if (provider.currentPayroll!.fines.isNotEmpty)
                        _buildFinesSection(provider.currentPayroll!),
                      if (provider.currentPayroll!.shiftDetails.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _buildShiftDetailsSection(provider.currentPayroll!.shiftDetails),
                      ],
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 110, AppSpacing.lg, AppSpacing.lg),
      children: const [
        SkeletonLoader(width: double.infinity, height: 60, borderRadius: AppRadius.lg),
        SizedBox(height: AppSpacing.lg),
        SkeletonLoader(width: double.infinity, height: 160, borderRadius: AppRadius.xl),
        SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(child: SkeletonLoader(width: double.infinity, height: 100, borderRadius: AppRadius.lg)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: SkeletonLoader(width: double.infinity, height: 100, borderRadius: AppRadius.lg)),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: SkeletonLoader(width: double.infinity, height: 100, borderRadius: AppRadius.lg)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: SkeletonLoader(width: double.infinity, height: 100, borderRadius: AppRadius.lg)),
          ],
        ),
      ],
    );
  }

  Widget _buildNoAccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle
            ),
            child: const Icon(Symbols.lock_rounded, size: 48, color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Доступ ограничен', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          Text('Для просмотра обратитесь к руководству', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildErrorState(PayrollProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle
            ),
            child: const Icon(Symbols.error_rounded, size: 48, color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Не удалось загрузить данные', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.xl),
          AnimatedPress(
            onTap: () => provider.loadMyPayroll(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient, 
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: const [AppColors.shadowLevel2]
              ),
              child: Text(
                'Попробовать снова', 
                style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w800)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle
              ),
              child: const Icon(Symbols.event_busy_rounded, size: 48, color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Данные отсутствуют', style: AppTypography.titleSmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Text('За выбранный период начислений нет', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
          ],
        ).animate().fadeIn(),
      ),
    );
  }

  Widget _buildMonthSelector(PayrollProvider provider) {
    final isAdmin = context.read<AuthProvider>().user?.role == 'admin';
    return Container(
      decoration: AppDecorations.cardElevated1.copyWith(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Symbols.chevron_left_rounded, color: AppColors.primary), 
            onPressed: () => provider.prevMonth(isAdmin)
          ),
          Column(
            children: [
              Text(
                DateFormat('yyyy').format(provider.currentDate), 
                style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900, letterSpacing: 2)
              ),
              Text(
                DateFormat('LLLL', 'ru').format(provider.currentDate).toUpperCase(), 
                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.1)
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Symbols.chevron_right_rounded, color: AppColors.primary), 
            onPressed: () => provider.nextMonth(isAdmin)
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildAdminListView(PayrollProvider provider) {
    final filteredList = _filteredPayrolls;
    
    // Получаем список уникальных должностей для фильтра
    final positions = provider.payrolls
        .map((p) => p.staff?.position)
        .where((pos) => pos != null)
        .toSet()
        .toList();

    return Column(
      children: [
        // Панель фильтров
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: AppDecorations.cardElevated1.copyWith(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            children: [
              // Поиск
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Поиск по имени...',
                  prefixIcon: const Icon(Symbols.search_rounded, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  // Фильтр по должности
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedPosition,
                          hint: const Text('Должность', style: TextStyle(fontSize: 14)),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Все должности')),
                            ...positions.map((pos) => DropdownMenuItem(value: pos, child: Text(pos!))),
                          ],
                          onChanged: (val) => setState(() => _selectedPosition = val),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                   // Фильтр по группе
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Consumer<GroupsProvider>(
                        builder: (context, groupsProvider, _) => DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedGroupId,
                            hint: const Text('Все группы', style: TextStyle(fontSize: 14)),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Все группы')),
                              ...groupsProvider.groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))),
                            ],
                            onChanged: (val) => setState(() => _selectedGroupId = val),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Фильтр по статусу
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedStatus,
                          hint: const Text('Статус', style: TextStyle(fontSize: 14)),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Все статусы')),
                            DropdownMenuItem(value: 'paid', child: Text('Выплачено')),
                            DropdownMenuItem(value: 'pending', child: Text('Ожидает')),
                            DropdownMenuItem(value: 'draft', child: Text('Черновик')),
                          ],
                          onChanged: (val) => setState(() => _selectedStatus = val),
                        ),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty || _selectedPosition != null || _selectedGroupId != null || _selectedStatus != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      icon: const Icon(Symbols.close_rounded, color: AppColors.error),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _selectedPosition = null;
                          _selectedGroupId = null;
                          _selectedStatus = null;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        
        if (filteredList.isEmpty)
          _buildEmptyState()
        else
          ...filteredList.map((p) => _buildPayrollListItem(p, provider)),
      ],
    );
  }

  Widget _buildPayrollListItem(Payroll p, PayrollProvider provider) {
    return AnimatedPress(
      onTap: () => provider.selectPayroll(p),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppDecorations.cardElevated1.copyWith(color: AppColors.surface),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                p.staff != null && p.staff!.fullName.isNotEmpty 
                    ? p.staff!.fullName[0].toUpperCase() 
                    : '?', 
                style: const TextStyle(color: AppColors.primary)
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.staff?.fullName ?? 'Неизвестно', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                  Text(p.staff?.position ?? 'Сотрудник', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(currencyFormat.format(p.total), style: AppTypography.labelLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900)),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Symbols.more_vert_rounded, color: AppColors.textTertiary),
              onSelected: (val) {
                if (val == 'delete') _onDeletePayroll(p);
                if (val == 'pay') _onUpdateStatus(p, 'paid');
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'pay', child: Row(children: [Icon(Symbols.check_circle_rounded, color: AppColors.success), SizedBox(width: 8), Text('Выплатить')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Symbols.delete_rounded, color: AppColors.error), SizedBox(width: 8), Text('Удалить')])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileCard(Payroll p) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Text(
              p.staff != null && p.staff!.fullName.isNotEmpty 
                  ? p.staff!.fullName[0].toUpperCase() 
                  : '?', 
              style: const TextStyle(color: Colors.white)
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.staff?.fullName ?? 'Неизвестно', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900)),
              Text(p.staff?.position ?? '', style: AppTypography.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(PayrollProvider provider, double total) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
            const Color(0xFF764BA2),
          ],
        ),
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10)
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30, 
            bottom: -30, 
            child: Icon(Symbols.account_balance_wallet_rounded, size: 160, color: Colors.white.withValues(alpha: 0.08))
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'К ВЫПЛАТЕ', 
                      style: AppTypography.labelSmall.copyWith(color: Colors.white.withValues(alpha: 0.7), letterSpacing: 2, fontWeight: FontWeight.w900)
                    ),
                    const Spacer(),
                    const Icon(Symbols.verified_rounded, color: Colors.white70, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  currencyFormat.format(total), 
                  style: AppTypography.displaySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -1)
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.full)
                  ),
                  child: Text(
                    'Статус: ${provider.currentPayroll!.status == 'paid' ? 'Выплачено' : (provider.currentPayroll!.status == 'pending' ? 'Ожидает' : 'Расчитано')}', 
                    style: AppTypography.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600)
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 100.ms, duration: 500.ms, curve: Curves.fastOutSlowIn);
  }

  Widget _buildDetailsGrid(PayrollProvider provider) {
    final p = provider.currentPayroll!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildInfoCard('Оклад', p.baseSalary, AppColors.primary, Symbols.payments_rounded, 0)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildInfoCard('Бонусы', p.bonuses, AppColors.success, Symbols.award_star_rounded, 1)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _buildInfoCard('Аванс', p.advance, const Color(0xFFF59E0B), Symbols.hourglass_top_rounded, 2)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildInfoCard('Вычеты', p.penalties, AppColors.error, Symbols.receipt_long_rounded, 3)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _buildInfoCard('Смен', p.workedShifts, AppColors.info, Symbols.calendar_month_rounded, 4)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _buildInfoCard('Дней', p.workedDays, AppColors.info, Symbols.today_rounded, 5)),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 450.ms);
  }

  Widget _buildInfoCard(String title, double amount, Color color, IconData icon, int index) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.cardElevated1.copyWith(color: AppColors.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8)
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            title == 'Смен' || title == 'Дней' ? amount.toInt().toString() : currencyFormat.format(amount), 
            style: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w900)
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: index % 2 == 0 ? -0.1 : 0.1);
  }

  Widget _buildAdminActions(Payroll p) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: AnimatedPress(
              onTap: () => _onAddFine(p),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Symbols.add_circle_rounded, color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text('Добавить штраф', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AnimatedPress(
              onTap: () => _onUpdateStatus(p, 'paid'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Symbols.check_circle_rounded, color: AppColors.success, size: 20),
                    SizedBox(width: 8),
                    Text('Выплатить все', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinesSection(Payroll p) {
    final fines = p.fines;
    final isAdmin = context.read<AuthProvider>().user?.role == 'admin';
    return Container(
      decoration: AppDecorations.cardElevated1.copyWith(color: AppColors.surface),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)
                ),
                child: const Icon(Symbols.warning_rounded, color: AppColors.error, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Детализация вычетов', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppColors.surfaceVariant),
          ),
          ...fines.map((fine) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fine.reason.isNotEmpty ? fine.reason : 'Прочий вычет', 
                        style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700)
                      ),
                      Text(
                        DateFormat('dd.MM.yyyy HH:mm').format(fine.date.toLocal()), 
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)
                      ),
                    ],
                  ),
                ),
                Text(
                  '-${currencyFormat.format(fine.amount)}', 
                  style: AppTypography.labelLarge.copyWith(color: AppColors.error, fontWeight: FontWeight.w900)
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Symbols.delete_rounded, color: AppColors.error, size: 20),
                    onPressed: () => _onDeleteFine(p, fine.id!),
                  ),
                ],
              ],
            ),
          )),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildShiftDetailsSection(List<ShiftDetail> details) {
    return Container(
      decoration: AppDecorations.cardElevated1.copyWith(color: AppColors.surface),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)
                ),
                child: const Icon(Symbols.history_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text('История смен', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppColors.surfaceVariant),
          ),
          ...details.map((detail) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd MMMM', 'ru').format(detail.date), 
                      style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)
                    ),
                    Text(
                      'Базово: ${currencyFormat.format(detail.earnings)}', 
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(detail.net), 
                      style: AppTypography.labelLarge.copyWith(
                        color: detail.net >= 0 ? AppColors.success : AppColors.error, 
                        fontWeight: FontWeight.w900
                      )
                    ),
                    if (detail.fines > 0)
                      Text(
                        'Штраф: -${currencyFormat.format(detail.fines)}', 
                        style: AppTypography.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 10)
                      ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }
}
