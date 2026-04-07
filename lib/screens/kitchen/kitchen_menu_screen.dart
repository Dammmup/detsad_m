import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/menu_model.dart';
import '../../core/services/kitchen_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/animated_press.dart';
import 'package:intl/intl.dart';

import 'dart:ui';
import '../../core/widgets/shimmer_loading.dart';

class KitchenMenuScreen extends StatefulWidget {
  const KitchenMenuScreen({super.key});

  @override
  State<KitchenMenuScreen> createState() => _KitchenMenuScreenState();
}

class _KitchenMenuScreenState extends State<KitchenMenuScreen> {
  final KitchenService _kitchenService = KitchenService();
  DailyMenu? _menu;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final menu = await _kitchenService.getTodayMenu();
      if (mounted) {
        setState(() {
          _menu = menu;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки меню: $e';
          _isLoading = false;
        });
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
              title: Text(
                'Меню на сегодня', 
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
                  onPressed: _fetchMenu
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: AppDecorations.pageBackground,
        child: _isLoading
            ? _buildSkeletonLoading()
            : _error != null
                ? _buildErrorView()
                : _menu == null
                    ? _buildEmptyView()
                    : _buildMenuView(),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 100, AppSpacing.lg, AppSpacing.lg),
      children: [
        const SkeletonLoader(width: double.infinity, height: 100, borderRadius: AppRadius.lg),
        const SizedBox(height: AppSpacing.lg),
        ...List.generate(4, (index) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: SkeletonLoader(width: double.infinity, height: 120, borderRadius: AppRadius.lg),
        )),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
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
            Text(
              'Упс! Что-то пошло не так', 
              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800)
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!, 
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary), 
              textAlign: TextAlign.center
            ),
            const SizedBox(height: AppSpacing.xl),
            AnimatedPress(
              onTap: _fetchMenu,
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
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle
            ),
            child: const Icon(Symbols.restaurant_menu_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Меню скоро появится', 
            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800)
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Повар уже готовит список блюд ✨', 
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)
          ),
          const SizedBox(height: AppSpacing.xl),
          AnimatedPress(
            onTap: _fetchMenu,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary, 
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: const [AppColors.shadowLevel1]
              ),
              child: Text(
                'Обновить данные', 
                style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w800)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        const SizedBox(height: 110),
        _buildInfoCard().animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
        const SizedBox(height: AppSpacing.lg),
        _buildMealCard('breakfast', 'Завтрак', Symbols.wb_sunny_rounded, 0),
        const SizedBox(height: AppSpacing.md),
        _buildMealCard('lunch', 'Обед', Symbols.light_mode_rounded, 1),
        const SizedBox(height: AppSpacing.md),
        _buildMealCard('snack', 'Полдник', Symbols.cookie_rounded, 2),
        const SizedBox(height: AppSpacing.md),
        _buildMealCard('dinner', 'Ужин', Symbols.nightlight_rounded, 3),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.cardElevated1.copyWith(
        color: AppColors.surface,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.6), 
              shape: BoxShape.circle
            ),
            child: const Icon(Symbols.calendar_today_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, d MMMM', 'ru').format(_menu!.date).toUpperCase(), 
                  style: AppTypography.labelSmall.copyWith(color: AppColors.primary90, letterSpacing: 1.2, fontWeight: FontWeight.w900)
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Symbols.groups_rounded, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      'Всего детей по списку: ', 
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)
                    ),
                    Text(
                      '${_menu!.totalChildCount}', 
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800)
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(String type, String title, IconData icon, int index) {
    final meal = _menu!.meals[type] ?? Meal(dishes: []);
    bool isServed = meal.isServed;

    return Container(
      decoration: AppDecorations.cardElevated1.copyWith(
        color: isServed ? AppColors.success.withValues(alpha: 0.02) : AppColors.surface,
        border: isServed ? Border.all(color: AppColors.success.withValues(alpha: 0.15)) : null,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey(type),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isServed ? AppColors.success : AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)
            ),
            child: Icon(icon, color: isServed ? AppColors.success : AppColors.primary, size: 24),
          ),
          title: Text(
            title, 
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: isServed ? AppColors.success : AppColors.textPrimary
            )
          ),
          subtitle: isServed 
            ? Row(
                children: [
                   const Icon(Symbols.done_all_rounded, size: 14, color: AppColors.success),
                   const SizedBox(width: 4),
                   Text(
                     'Выдано в ${DateFormat('HH:mm').format(meal.servedAt!)}', 
                     style: AppTypography.bodySmall.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)
                   ),
                ],
              )
            : Text(
                'Ожидает подтверждения', 
                style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)
              ),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1, color: AppColors.primary20),
                const SizedBox(height: AppSpacing.md),
                ...meal.dishes.map((dish) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dish.name, 
                          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w500)
                        )
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: AppSpacing.lg),
                AnimatedPress(
                  onTap: () => isServed ? _cancelMeal(type) : _showServeDialog(type),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: isServed ? null : AppColors.primaryGradient,
                      color: isServed ? AppColors.surfaceVariant : null,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: isServed ? null : [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4)
                        )
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isServed ? Symbols.undo_rounded : Symbols.check_circle_rounded, 
                            color: isServed ? AppColors.textPrimary : Colors.white, 
                            size: 20
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            isServed ? 'Отменить отметку' : 'Подтвердить выдачу', 
                            style: AppTypography.labelLarge.copyWith(
                              color: isServed ? AppColors.textPrimary : Colors.white,
                              fontWeight: FontWeight.w800,
                            )
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  void _showServeDialog(String type) {
    final TextEditingController countController = TextEditingController(text: _menu!.totalChildCount.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            const Icon(Symbols.restaurant_rounded, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text('Подтверждение', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Укажите количество детей, получивших питание:', 
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w800),
              decoration: AppDecorations.inputDecoration(
                hintText: 'Например: 25', 
                labelText: 'Количество детей'
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, AppSpacing.md, AppSpacing.md),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text(
              'Отмена', 
              style: AppTypography.labelLarge.copyWith(color: AppColors.textTertiary)
            )
          ),
          AnimatedPress(
            onTap: () {
              final int count = int.tryParse(countController.text) ?? _menu!.totalChildCount;
              Navigator.pop(context);
              _serveMeal(type, count);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Готово', 
                style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _serveMeal(String type, int count) async {
    try {
      final updatedMenu = await _kitchenService.serveMeal(_menu!.id, type, count);
      if (!mounted) return;
      if (updatedMenu != null) setState(() => _menu = updatedMenu);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _cancelMeal(String type) async {
    try {
      final updatedMenu = await _kitchenService.cancelMeal(_menu!.id, type);
      if (!mounted) return;
      if (updatedMenu != null) setState(() => _menu = updatedMenu);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error));
    }
  }
}
