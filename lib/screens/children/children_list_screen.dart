import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart'; // Для работы с буфером обмена
import '../../../models/child_model.dart';
import '../../../models/user_model.dart';
import '../../../core/services/children_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/groups_provider.dart';
import 'add_child_screen.dart'; // Импорт экрана добавления ребенка

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
    final ctx = context; // сохраняем контекст
    if (!ctx.mounted) {
      return;
    }
    try {
      final authProvider = Provider.of<AuthProvider>(ctx, listen: false);
      final groupsProvider = Provider.of<GroupsProvider>(ctx, listen: false);
      final User? currentUser = authProvider.user;

      // Load all groups to have them available for name lookups
      await groupsProvider.loadGroups();
      if (!ctx.mounted) return;
      final allGroups = groupsProvider.groups;
      
      // Debug logging
      print('ChildrenListScreen | Loaded ${allGroups.length} groups');
      print('ChildrenListScreen | Current user ID: ${currentUser?.id}');
      print('ChildrenListScreen | Current user role: ${currentUser?.role}');
      for (var group in allGroups) {
        print('ChildrenListScreen | Group: ${group.name}, teacher: ${group.teacher}, id: ${group.id}');
      }

      // Проверяем, является ли пользователь преподавателем или заменителем
      bool isTeacherOrSubstitute = currentUser != null &&
          (currentUser.role == 'teacher' || currentUser.role == 'substitute');

      // Проверяем, имеет ли пользователь права администратора
      bool isAdmin = currentUser != null &&
          (currentUser.role == 'admin' ||
              currentUser.role == 'director' ||
              currentUser.role == 'owner');

      if (isAdmin) {
        // Для администраторов и руководителей загружаем всех детей
        children = await _childrenService.getAllChildren();
        if (!ctx.mounted) return; // проверяем контекст после await
      } else if (isTeacherOrSubstitute) {
        // Find groups assigned to the current teacher from the list of all groups
        final teacherGroups = allGroups.where((group) => group.teacher == currentUser.id).toList();
        print('ChildrenListScreen | Teacher groups found: ${teacherGroups.length}');
        for (var group in teacherGroups) {
          print('ChildrenListScreen | Teacher group: ${group.name}');
        }
        List<Child> teacherChildren = [];

        if (teacherGroups.isNotEmpty) {
          // For each teacher group, get the children in that group
          for (var group in teacherGroups) {
            List<Child> childrenInGroup = await _childrenService.getChildrenByGroupId(group.id);
            print('ChildrenListScreen | Children in group ${group.name}: ${childrenInGroup.length}');
            teacherChildren.addAll(childrenInGroup);
          }
        } else {
          // Если у преподавателя нет назначенных групп, не загружаем детей
          teacherChildren = [];
        }

        children = teacherChildren;
        print('ChildrenListScreen | Total children for teacher: ${children.length}');
      } else {
        // Для других ролей также загружаем всех детей, но с возможными ограничениями на бэкенде
        children = await _childrenService.getAllChildren();
        if (!ctx.mounted) return; // проверяем контекст после await
      }

      // Применяем фильтрацию после загрузки детей
      _applyFilters();
    } on Exception catch (e) {
      String errorMessage = e.toString();

      // Check for specific error messages
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
      final ctx = context; // сохраняем контекст
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
        final ctx = context; // сохраняем контекст
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
      // For now, just show all children, but in a real implementation
      // this would filter by the user's assigned group
      _filteredChildren = children;
    }
    setState(() {
      // Update filtered list
      _filteredChildren = List.from(_filteredChildren);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Дети'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Проверяем права пользователя на добавление ребенка
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
                    // Навигация к экрану добавления ребенка
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AddChildScreen()),
                    );

                    // Если ребенок был успешно добавлен, обновляем список
                    if (result == true) {
                      _loadChildren(); // Перезагружаем список детей
                    }
                  },
                );
              } else {
                return Container(); // Не отображаем кнопку, если нет прав
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
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

              // Filter controls - only visible to admins and alternative staff members
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final currentUser = authProvider.user;
                  bool isAdminOrAlternative = currentUser != null &&
                      (currentUser.role == 'admin' ||
                          currentUser.role == 'director' ||
                          currentUser.role == 'owner' ||
                          currentUser.role ==
                              'substitute'); // assuming 'substitute' is alternative staff

                  if (isAdminOrAlternative) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha((0.1 * 255).round()),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
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
                                selectedColor: Colors.blue
                                    .shade200, // Changed from purple to blue
                                backgroundColor: Colors.grey.shade200,
                                checkmarkColor: Colors.blue.shade700,
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
                                selectedColor: Colors.blue
                                    .shade200, // Changed from purple to blue
                                backgroundColor: Colors.grey.shade200,
                                checkmarkColor: Colors.blue.shade700,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Return empty container if user is not admin or substitute
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
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey
                                        .withAlpha((0.1 * 255).round()),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
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
                                  if (children.isNotEmpty && _filteredChildren.isEmpty)
                                    const SizedBox(height: 8),
                                  if (children.isNotEmpty && _filteredChildren.isEmpty)
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
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey
                                          .withAlpha((0.1 * 255).round()),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
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
                                                final ctx =
                                                    context; // сохраняем контекст до await
                                                await Clipboard.setData(
                                                    ClipboardData(
                                                        text: child
                                                            .parentPhone!));
                                                if (!ctx.mounted) {
                                                  return; // правильная проверка
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
                                                      color: Colors.blue,
                                                      decoration:
                                                          TextDecoration
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
                                            color: Colors.blue.withAlpha(
                                                (0.1 * 255).round()),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _getChildGroupInfo(child),
                                            style: const TextStyle(
                                                color: Colors.blue),
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

  // Helper method to get child group info
  String _getChildGroupInfo(Child child) {
   // Use groupName from populated API response first
   if (child.groupName != null && child.groupName!.isNotEmpty) {
     return child.groupName!;
   }
   
   // Fallback to groupId if groupName is not available
   if (child.groupId == null) {
     return 'Группа не указана';
   }

   // Try to find group in provider
   final groupsProvider = Provider.of<GroupsProvider>(context, listen: false);
   final group = groupsProvider.getGroupById(child.groupId!);
   if (group != null) {
     return group.name;
   }
   
   // Last resort - return the ID
   return child.groupId!;
 }

  // Helper method to format birthday in the format: day, month (in words), year
  String _formatBirthday(String birthdayString) {
    try {
      // Parse the birthday string to a DateTime object
      DateTime date = DateTime.parse(birthdayString);

      // Define month names in Russian
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

      // Extract day, month, and year
      int day = date.day;
      int monthIndex =
          date.month - 1; // month is 1-indexed, but our list is 0-indexed
      int year = date.year;

      // Format the string as "day, month (in words), year"
      return '$day ${months[monthIndex]}, $year';
    } catch (e) {
      // If parsing fails, return the original string
      return birthdayString;
    }
  }
}
