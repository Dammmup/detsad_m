import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../models/child_model.dart';
import '../../../models/user_model.dart';
import '../../../core/services/children_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/groups_provider.dart';
import 'add_child_screen.dart';

class ChildrenListScreen extends StatefulWidget {
  const ChildrenListScreen({super.key});

  @override
  State<ChildrenListScreen> createState() => _ChildrenListScreenState();
}

class _ChildrenListScreenState extends State<ChildrenListScreen> {
  List<Child> children = [];
  List<Child> _filteredChildren = [];
  String _selectedFilter = 'all';
  bool isLoading = true;
  final ChildrenService _childrenService = ChildrenService();

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final ctx = context;
    if (!ctx.mounted) {
      return;
    }
    try {
      final authProvider = Provider.of<AuthProvider>(ctx, listen: false);
      final groupsProvider = Provider.of<GroupsProvider>(ctx, listen: false);
      final User? currentUser = authProvider.user;

      await groupsProvider.loadGroups();
      if (!ctx.mounted) return;
      final allGroups = groupsProvider.groups;

      AppLogger.info('ChildrenListScreen | Loaded ${allGroups.length} groups');
      AppLogger.debug('ChildrenListScreen | Current user ID: ${currentUser?.id}');
      AppLogger.debug('ChildrenListScreen | Current user role: ${currentUser?.role}');
      for (var group in allGroups) {
        AppLogger.debug(
            'ChildrenListScreen | Group: ${group.name}, teacher: ${group.teacher}, id: ${group.id}');
      }

      bool isTeacherOrSubstitute = currentUser != null &&
          (currentUser.role == 'teacher' || currentUser.role == 'substitute');

      bool isAdmin = currentUser != null &&
          (currentUser.role == 'admin' ||
              currentUser.role == 'director' ||
              currentUser.role == 'owner');

      if (isAdmin) {
        children = await _childrenService.getAllChildren();
        if (!ctx.mounted) return;
      } else if (isTeacherOrSubstitute) {
        final teacherGroups = allGroups
            .where((group) => group.teacher == currentUser.id)
            .toList();
        AppLogger.info(
            'ChildrenListScreen | Teacher groups found: ${teacherGroups.length}');
        for (var group in teacherGroups) {
          AppLogger.debug('ChildrenListScreen | Teacher group: ${group.name}');
        }
        List<Child> teacherChildren = [];

        if (teacherGroups.isNotEmpty) {
          for (var group in teacherGroups) {
            List<Child> childrenInGroup =
                await _childrenService.getChildrenByGroupId(group.id);
            AppLogger.info(
                'ChildrenListScreen | Children in group ${group.name}: ${childrenInGroup.length}');
            teacherChildren.addAll(childrenInGroup);
          }
        } else {
          teacherChildren = [];
        }

        children = teacherChildren;
        AppLogger.info(
            'ChildrenListScreen | Total children for teacher: ${children.length}');
      } else {
        children = await _childrenService.getAllChildren();
        if (!ctx.mounted) return;
      }

      _applyFilters();
    } on Exception catch (e) {
      String errorMessage = e.toString();

      if (errorMessage.contains('Нет подключения к интернету')) {
        errorMessage = 'Нет подключения к интернету';
      } else if (errorMessage.contains('Нет прав для просмотра') ||
          errorMessage.contains('unauthorized') ||
          errorMessage.contains('403')) {
        errorMessage = 'Нет прав для просмотра списка детей';
      } else if (errorMessage.contains('Данные не найдены') ||
          errorMessage.contains('not found') ||
          errorMessage.contains('404')) {
        errorMessage = 'Данные о детях не найдены';
      } else {
        errorMessage =
            'Ошибка загрузки списка детей. Проверьте подключение к интернету';
      }
      final ctx = context;
      if (!ctx.mounted) {
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      String errorMessage =
          'Ошибка загрузки списка детей. Проверьте подключение к интернету';

      if (mounted) {
        final ctx = context;
        if (!ctx.mounted) {
          return;
        }
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (ctx.mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    if (_selectedFilter == 'all') {
      _filteredChildren = children;
    } else if (_selectedFilter == 'by_group') {
      _filteredChildren = children;
    }
    setState(() {
      _filteredChildren = List.from(_filteredChildren);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Дети'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final currentUser = authProvider.user;
              bool canAddChild = currentUser != null &&
                  (currentUser.role == 'admin' ||
                      currentUser.role == 'director' ||
                      currentUser.role == 'owner');

              if (canAddChild) {
                return IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddChildScreen()),
                    );

                    if (result == true) {
                      _loadChildren();
                    }
                  },
                );
              } else {
                return Container();
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: AppDecorations.pageBackground,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Список детей',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800]),
              ),
              const SizedBox(height: 16),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final currentUser = authProvider.user;
                  bool isAdminOrAlternative = currentUser != null &&
                      (currentUser.role == 'admin' ||
                          currentUser.role == 'director' ||
                          currentUser.role == 'owner' ||
                          currentUser.role == 'substitute');

                  if (isAdminOrAlternative) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AppDecorations.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Фильтры',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilterChip(
                                label: const Text('Все'),
                                selected: _selectedFilter == 'all',
                                onSelected: (bool selected) {
                                  setState(() {
                                    _selectedFilter = selected ? 'all' : 'all';
                                  });
                                  _applyFilters();
                                },
                                selectedColor: AppColors.primaryLight,
                                backgroundColor: Colors.grey.shade200,
                                checkmarkColor: AppColors.primary,
                              ),
                              FilterChip(
                                label: const Text('По группам'),
                                selected: _selectedFilter == 'by_group',
                                onSelected: (bool selected) {
                                  setState(() {
                                    _selectedFilter =
                                        selected ? 'by_group' : 'all';
                                  });
                                  _applyFilters();
                                },
                                selectedColor: AppColors.primaryLight,
                                backgroundColor: Colors.grey.shade200,
                                checkmarkColor: AppColors.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Container();
                  }
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredChildren.isEmpty
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: AppDecorations.cardDecoration,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.people_outline,
                                      size: 48, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Нет данных о детях',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                  if (children.isNotEmpty &&
                                      _filteredChildren.isEmpty)
                                    const SizedBox(height: 8),
                                  if (children.isNotEmpty &&
                                      _filteredChildren.isEmpty)
                                    const Text(
                                      'Попробуйте изменить фильтры',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                    ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredChildren.length,
                            itemBuilder: (context, index) {
                              final child = _filteredChildren[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: AppDecorations.cardDecoration,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        child.fullName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (child.birthday != null) ...[
                                        Row(
                                          children: [
                                            const Icon(Icons.cake,
                                                size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                                'День рождения: ${_formatBirthday(child.birthday!)}',
                                                style: TextStyle(
                                                    color: Colors.grey[700])),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      if (child.parentName != null) ...[
                                        Row(
                                          children: [
                                            const Icon(Icons.person,
                                                size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                                'Родитель: ${child.parentName}',
                                                style: TextStyle(
                                                    color: Colors.grey[700])),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      if (child.parentPhone != null) ...[
                                        Row(
                                          children: [
                                            const Icon(Icons.phone,
                                                size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            GestureDetector(
                                              onTap: () async {
                                                final ctx = context;
                                                await Clipboard.setData(
                                                    ClipboardData(
                                                        text: child
                                                            .parentPhone!));
                                                if (!ctx.mounted) {
                                                  return;
                                                }
                                                ScaffoldMessenger.of(ctx)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Номер телефона скопирован: ${child.parentPhone}'),
                                                    duration: const Duration(
                                                        seconds: 2),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                  'Телефон: ${child.parentPhone}',
                                                  style: const TextStyle(
                                                      color: AppColors.primary,
                                                      decoration: TextDecoration
                                                          .underline)),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (child.groupId != null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withAlpha((0.1 * 255).round()),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _getChildGroupInfo(child),
                                            style: const TextStyle(
                                                color: AppColors.primary),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getChildGroupInfo(Child child) {
    if (child.groupName != null && child.groupName!.isNotEmpty) {
      return child.groupName!;
    }

    if (child.groupId == null) {
      return 'Группа не указана';
    }

    final groupsProvider = Provider.of<GroupsProvider>(context, listen: false);
    final group = groupsProvider.getGroupById(child.groupId!);
    if (group != null) {
      return group.name;
    }

    return child.groupId!;
  }

  String _formatBirthday(String birthdayString) {
    try {
      DateTime date = DateTime.parse(birthdayString);

      const List<String> months = [
        'января',
        'февраля',
        'марта',
        'апреля',
        'мая',
        'июня',
        'июля',
        'августа',
        'сентября',
        'октября',
        'ноября',
        'декабря'
      ];

      int day = date.day;
      int monthIndex = date.month - 1;
      int year = date.year;

      return '$day ${months[monthIndex]}, $year';
    } catch (e) {
      return birthdayString;
    }
  }
}
