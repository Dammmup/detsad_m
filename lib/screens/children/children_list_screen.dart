import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/child_model.dart';
import '../../../models/user_model.dart';
import '../../../core/services/children_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/groups_provider.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'add_child_screen.dart';

class ChildrenListScreen extends StatefulWidget {
  const ChildrenListScreen({super.key});

  @override
  State<ChildrenListScreen> createState() => _ChildrenListScreenState();
}

class _ChildrenListScreenState extends State<ChildrenListScreen> {
  List<Child> children = [];
  List<Child> _filteredChildren = [];
  String _searchQuery = '';
  String? _selectedGroupId;
  bool? _selectedActiveStatus;
  bool isLoading = true;
  final ChildrenService _childrenService = ChildrenService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    try {
      setState(() => isLoading = true);
      final authProvider = context.read<AuthProvider>();
      final groupsProvider = context.read<GroupsProvider>();
      final User? currentUser = authProvider.user;

      await groupsProvider.loadGroups();
      final allGroups = groupsProvider.groups;

      if (currentUser != null && ['teacher', 'substitute', 'assistant'].contains(currentUser.role)) {
        final teacherGroupIds = allGroups
            .where((g) => g.teacher == currentUser.id || g.teacherId == currentUser.id || g.assistantId == currentUser.id)
            .map((g) => g.id)
            .toList();
        
        if (teacherGroupIds.isNotEmpty) {
          children = await _childrenService.getChildrenByGroupIds(teacherGroupIds);
        } else {
          children = [];
        }
      } else {
        children = await _childrenService.getAllChildren();
      }

      _applyFilters();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating)
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredChildren = children.where((child) {
        final matchesSearch = child.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (child.parentPhone?.contains(_searchQuery) ?? false);
        
        final matchesGroup = _selectedGroupId == null || child.groupId == _selectedGroupId;
        
        final matchesActive = _selectedActiveStatus == null || child.active == _selectedActiveStatus;
        
        return matchesSearch && matchesGroup && matchesActive;
      }).toList();
    });
  }

  Future<void> _deleteChild(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление'),
        content: const Text('Вы уверены, что хотите удалить этого ребенка?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Удалить')
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => isLoading = true);
        await _childrenService.deleteChild(id);
        _loadChildren();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления: $e'), backgroundColor: AppColors.error)
          );
        }
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;
    bool canAddChild = currentUser != null && ['admin', 'director', 'owner'].contains(currentUser.role);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              title: Text(
                'Воспитанники', 
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
                if (canAddChild)
                  IconButton(
                    icon: const Icon(Symbols.person_add_rounded, color: AppColors.primary90),
                    onPressed: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddChildScreen()));
                      if (result == true) _loadChildren();
                    },
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
            _buildSearchAndFilters(),
            Expanded(
              child: isLoading
                  ? _buildSkeletonLoading()
                  : _filteredChildren.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                          itemCount: _filteredChildren.length,
                          itemBuilder: (context, index) => _buildChildCard(_filteredChildren[index], index),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final groups = context.watch<GroupsProvider>().groups;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Column(
        children: [
          Container(
            decoration: AppDecorations.cardElevated1,
            child: TextField(
              controller: _searchController,
              onChanged: (v) {
                setState(() => _searchQuery = v);
                _applyFilters();
              },
              decoration: AppDecorations.searchInputDecoration(hintText: 'Поиск по имени или телефону...').copyWith(
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Symbols.close_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _applyFilters();
                      },
                    )
                  : null,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: AppDecorations.cardElevated1.copyWith(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedGroupId,
                      hint: Text('Все группы', style: AppTypography.bodySmall),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: null, child: Text('Все группы', style: AppTypography.bodySmall)),
                        ...groups.map((g) => DropdownMenuItem(
                          value: g.id, 
                          child: Text(g.name, style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis)
                        )),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedGroupId = val);
                        _applyFilters();
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: AppDecorations.cardElevated1.copyWith(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<bool?>(
                      value: _selectedActiveStatus,
                      hint: Text('Все статусы', style: AppTypography.bodySmall),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: null, child: Text('Все статусы', style: AppTypography.bodySmall)),
                        DropdownMenuItem(value: true, child: Text('Активные', style: AppTypography.bodySmall)),
                        DropdownMenuItem(value: false, child: Text('В архиве', style: AppTypography.bodySmall)),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedActiveStatus = val);
                        _applyFilters();
                      },
                    ),
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty || _selectedGroupId != null || _selectedActiveStatus != null) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                      _selectedGroupId = null;
                      _selectedActiveStatus = null;
                    });
                    _applyFilters();
                  },
                  icon: const Icon(Symbols.filter_alt_off_rounded, color: AppColors.error),
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 8,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: SkeletonLoader(width: double.infinity, height: 88, borderRadius: AppRadius.lg),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Symbols.sentiment_dissatisfied_rounded, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text('Никого не нашли', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary)),
          Text('Попробуйте другой запрос', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildChildCard(Child child, int index) {
    final currentUser = context.read<AuthProvider>().user;
    final bool canEdit = currentUser != null && ['admin', 'director', 'owner'].contains(currentUser.role);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: AppDecorations.cardElevated1,
      child: InkWell(
        onTap: () async {
          if (canEdit) {
            final result = await Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => AddChildScreen(child: child))
            );
            if (result == true) _loadChildren();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _buildAvatar(child),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.fullName, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    if (child.parentPhone != null)
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: child.parentPhone!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Номер скопирован'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1))
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(Symbols.call_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              child.parentPhone!, 
                              style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1), 
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Text(
                        child.groupName ?? 'Без группы', 
                        style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10)
                      ),
                    ),
                  ],
                ),
              ),
              if (canEdit)
                PopupMenuButton<String>(
                  icon: const Icon(Symbols.more_vert_rounded, color: AppColors.textTertiary),
                  onSelected: (val) {
                    if (val == 'edit') {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => AddChildScreen(child: child))
                      ).then((res) => {if (res == true) _loadChildren()});
                    } else if (val == 'delete') {
                      _deleteChild(child.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Symbols.edit_rounded, size: 20), SizedBox(width: 8), Text('Изменить')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Symbols.delete_rounded, size: 20, color: AppColors.error), SizedBox(width: 8), Text('Удалить', style: TextStyle(color: AppColors.error))])),
                  ],
                )
              else
                const Icon(Symbols.chevron_right_rounded, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 40).ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildAvatar(Child child) {
    String? photoUrl = child.photo;
    if (photoUrl != null && photoUrl.isNotEmpty && !photoUrl.startsWith('http')) {
      photoUrl = '${ApiConstants.baseUrl.replaceAll(RegExp(r'/$'), '')}/$photoUrl';
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        shape: BoxShape.circle,
        image: photoUrl != null && photoUrl.isNotEmpty 
            ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) 
            : null,
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
}
