import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/animated_press.dart';
import '../../models/user_model.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  final ApiService _apiService = ApiService();
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.get(ApiConstants.users);
      if (response.data != null && response.data is List) {
        final List<User> loadedUsers = (response.data as List)
            .map((userJson) => User.fromJson(userJson))
            .toList();

        if (mounted) {
          setState(() {
            _users = loadedUsers;
            _isLoading = false;
          });
          _filterUsers();
        }
      } else {
        throw Exception('Неверный формат данных сервера');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка загрузки сотрудников: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _filterUsers() {
    if (!mounted) return;
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchSearch = _searchQuery.isEmpty ||
            user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.phone.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchRole = _selectedRole == null || user.role == _selectedRole;
        return matchSearch && matchRole;
      }).toList();
      
      // Сортировка: активные сверху, затем по фамилии
      _filteredUsers.sort((a, b) {
        if (a.active != b.active) {
          return a.active ? -1 : 1;
        }
        return a.lastName.compareTo(b.lastName);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Сотрудники',
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
      body: Container(
        height: double.infinity,
        decoration: AppDecorations.pageBackground,
        child: Column(
          children: [
            const SizedBox(height: 100),
            _buildSearchAndFilter(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error != null
                      ? _buildErrorState()
                      : _filteredUsers.isEmpty
                          ? _buildEmptyState()
                          : _buildUsersList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    // Collect unique roles
    final roles = _users.map((u) => u.role).toSet().toList()..sort();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (val) {
              _searchQuery = val;
              _filterUsers();
            },
            decoration: AppDecorations.searchInputDecoration(
              hintText: 'Поиск по имени или телефону',
            ),
          ),
          if (roles.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: const Text('Все'),
                      selected: _selectedRole == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedRole = null;
                        });
                        _filterUsers();
                      },
                      selectedColor: AppColors.primary10,
                      labelStyle: AppTypography.labelMedium.copyWith(
                        color: _selectedRole == null ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  ...roles.map((role) {
                    final isSelected = _selectedRole == role;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(_getRoleName(role)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedRole = selected ? role : null;
                          });
                          _filterUsers();
                        },
                        selectedColor: AppColors.primary10,
                        labelStyle: AppTypography.labelMedium.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ).animate().fadeIn().slideX(begin: 0.1, end: 0),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return RefreshIndicator(
      onRefresh: _loadUsers,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
        itemCount: _filteredUsers.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return _buildUserCard(user, index);
        },
      ),
    );
  }

  Widget _buildUserCard(User user, int index) {
    return AnimatedPress(
      onTap: () {
        Navigator.pushNamed(context, '/staff-profile', arguments: user);
      },
      child: Container(
        decoration: AppDecorations.cardElevated1,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Stack(
              children: [
                _buildAvatar(user),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: user.active ? AppColors.success : AppColors.grey400,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName.isNotEmpty ? user.fullName : 'Без имени',
                    style: AppTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Symbols.call_rounded, size: 14, color: AppColors.grey500),
                      const SizedBox(width: 4),
                      Text(
                        user.phone.isNotEmpty ? user.phone : 'Нет телефона',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.grey600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildBadge(_getRoleName(user.role), AppColors.primary),
                      if (user.position != null && user.position!.isNotEmpty)
                        _buildBadge(user.position!, AppColors.info),
                      if (user.department != null && user.department!.isNotEmpty)
                        _buildBadge(user.department!, AppColors.secondary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Symbols.chevron_right_rounded, color: AppColors.grey300),
          ],
        ),
      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05, end: 0),
    );
  }

  Widget _buildAvatar(User user) {
    String? avatarUrl = user.avatar;
    if (avatarUrl != null && avatarUrl.isNotEmpty && !avatarUrl.startsWith('http')) {
      avatarUrl = '${ApiConstants.baseUrl.replaceAll(RegExp(r'/$'), '')}/$avatarUrl';
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.primary10,
      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
          ? NetworkImage(avatarUrl)
          : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Text(
              user.firstName.isNotEmpty
                  ? user.firstName.substring(0, 1).toUpperCase()
                  : '?',
              style: AppTypography.titleLarge.copyWith(color: AppColors.primary),
            )
          : null,
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(color: color, fontSize: 10),
      ),
    );
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'admin': return 'Администратор';
      case 'manager': return 'Менеджер';
      case 'teacher': return 'Воспитатель';
      case 'assistant': return 'Няня';
      case 'nurse': return 'Медсестра';
      case 'cook': return 'Повар';
      case 'guard': return 'Охрана';
      case 'buhgalter': return 'Бухгалтер';
      default: return role;
    }
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: 5,
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
              onPressed: _loadUsers,
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
          const Icon(Symbols.group_off_rounded, size: 64, color: AppColors.grey300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedRole != null
                ? 'По вашему запросу ничего не найдено'
                : 'Список сотрудников пуст',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.grey500),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty || _selectedRole != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedRole = null;
                });
                _filterUsers();
              },
              child: const Text('Очистить фильтры'),
            ),
          ]
        ],
      ).animate().fadeIn(),
    );
  }
}
