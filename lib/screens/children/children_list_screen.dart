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
  bool isLoading = true;
  bool _initialLoadComplete = false; // Флаг для отслеживания завершения начальной загрузки
  final ChildrenService _childrenService = ChildrenService();

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final ctx = context; // сохраняем контекст

    try {
      // Если данные уже были загружены ранее, просто используем их
      final groupsProvider = Provider.of<GroupsProvider>(ctx, listen: false);
      
      if (!_initialLoadComplete && !groupsProvider.hasLoaded) {
        setState(() {
          isLoading = true;
        });
      }

      // Получаем информацию о текущем пользователе
      final authProvider = Provider.of<AuthProvider>(ctx, listen: false);
      final User? currentUser = authProvider.user;

      if (currentUser != null && currentUser.role == 'teacher') {
        // Если пользователь - воспитатель, загружаем только детей из его групп
        await groupsProvider.loadGroupsByTeacherId(currentUser.id);
        if (!ctx.mounted) return; // проверяем контекст после await

        final teacherGroups = groupsProvider.groups;

        // Получаем ID групп, в которых воспитатель является учителем
        List<String> groupIds = teacherGroups
            .map((group) => group['_id'] ?? group['id'])
            .toList()
            .cast<String>();

        // Загружаем всех детей и фильтруем только тех, кто принадлежит к группам воспитателя
        List<Child> allChildren = await _childrenService.getAllChildren();
        if (!ctx.mounted) return; // проверяем контекст после await

        children = allChildren.where((child) {
          if (child.groupId == null) return false;

          // Проверяем, принадлежит ли ребенок к одной из групп воспитателя
          String childGroupId;
          if (child.groupId is Map) {
            // Если groupId - это объект группы, извлекаем ID
            final groupMap = child.groupId as Map;
            childGroupId = groupMap['_id'] ?? groupMap['id'] ?? '';
          } else {
            // Если groupId - это строка, используем его напрямую
            childGroupId = child.groupId.toString();
          }

          return groupIds.contains(childGroupId);
        }).toList();
      } else {
        // Для других ролей (администратор и т.д.) загружаем всех детей
        children = await _childrenService.getAllChildren();
        if (!ctx.mounted) return; // проверяем контекст после await
      }
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
        errorMessage = 'Ошибка загрузки списка детей. Проверьте подключение к интернету';
      }

      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      String errorMessage = 'Ошибка загрузки списка детей. Проверьте подключение к интернету';
      
      if (mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (ctx.mounted) {
        setState(() {
          isLoading = false;
          _initialLoadComplete = true;
        });
      }
    }
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
          // Добавляем кнопку "Добавить ребенка" в правую часть AppBar
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // Навигация к экрану добавления ребенка
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddChildScreen()),
              );

              // Если ребенок был успешно добавлен, обновляем список
              if (result == true) {
                _loadChildren(); // Перезагружаем список детей
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
              Expanded(
                child: isLoading && children.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : children.isEmpty
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
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 48, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'Нет данных о детях',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: children.length,
                            itemBuilder: (context, index) {
                              final child = children[index];
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
    if (child.groupId == null) {
      return 'Группа не указана';
    }

    // If groupId is a map (object), extract the name
    if (child.groupId is Map) {
      final groupMap = child.groupId as Map;
      return groupMap['name'] ?? 'Группа не указана';
    }

    // If groupId is a string, return it directly
    return 'Группа: ${child.groupId.toString()}';
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
