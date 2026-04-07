import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/child_model.dart';
import '../../../core/services/children_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_press.dart';
import '../../../core/widgets/shimmer_loading.dart';

class DocumentsListScreen extends StatefulWidget {
  const DocumentsListScreen({super.key});

  @override
  State<DocumentsListScreen> createState() => _DocumentsListScreenState();
}

class _DocumentsListScreenState extends State<DocumentsListScreen> {
  List<Child> children = [];
  bool isLoading = true;
  final ChildrenService _childrenService = ChildrenService();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      setState(() => isLoading = true);
      final data = await _childrenService.getAllChildren();
      if (mounted) {
        setState(() {
          children = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: $e'), 
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => isLoading = false);
      }
    }
  }

  List<Child> get filteredChildren {
    if (searchQuery.isEmpty) return children;
    return children.where((child) => 
      child.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
      (child.iin?.contains(searchQuery) ?? false)
    ).toList();
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
                'База детей', 
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
                  onPressed: _loadChildren,
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
            _buildSearchField(),
            Expanded(
              child: isLoading
                  ? _buildSkeletonLoading()
                  : filteredChildren.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
                          itemCount: filteredChildren.length,
                          itemBuilder: (context, index) {
                            final child = filteredChildren[index];
                            return _buildChildCard(child, index);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Container(
        decoration: AppDecorations.cardElevated1,
        child: TextField(
          onChanged: (value) => setState(() => searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Поиск по имени или ИИН...',
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
            prefixIcon: const Icon(Symbols.search_rounded, color: AppColors.primary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: SkeletonLoader(width: double.infinity, height: 180, borderRadius: AppRadius.lg),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery.isEmpty ? Symbols.folder_off_rounded : Symbols.search_off_rounded, 
            size: 64, 
            color: AppColors.textTertiary
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            searchQuery.isEmpty ? 'Нет данных о детях' : 'Ничего не найдено', 
            style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary)
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildChildCard(Child child, int index) {
    return AnimatedPress(
      onTap: () {}, // Future details screen
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: AppDecorations.cardElevated1,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.05), Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Symbols.child_care_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.fullName, 
                          style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900)
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            child.groupId ?? 'Без группы', 
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary, 
                              fontWeight: FontWeight.bold
                            )
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Symbols.chevron_right_rounded, color: AppColors.textTertiary),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                children: [
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: AppSpacing.md),
                  _buildDetailRow(Symbols.badge_rounded, 'ИИН', child.iin ?? 'Не указан'),
                  const SizedBox(height: 8),
                  _buildDetailRow(Symbols.cake_rounded, 'Дата рождения', child.birthday ?? 'Не указана'),
                  const SizedBox(height: 8),
                  _buildDetailRow(Symbols.person_rounded, 'Родитель', child.parentName ?? 'Не указан'),
                  const SizedBox(height: 8),
                  _buildDetailRow(Symbols.phone_rounded, 'Контакт', child.parentPhone ?? 'Не указан', isPhone: true),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 40).ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isPhone = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary.withValues(alpha: 0.5)),
        const SizedBox(width: 10),
        Text('$label:', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value, 
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isPhone ? AppColors.primary : AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          )
        ),
      ],
    );
  }
}
