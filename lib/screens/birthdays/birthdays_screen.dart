import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/child_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/groups_provider.dart';
import '../../core/services/children_service.dart';

class BirthdaysScreen extends StatefulWidget {
  const BirthdaysScreen({Key? key}) : super(key: key);

  @override
  State<BirthdaysScreen> createState() => _BirthdaysScreenState();
}

class _BirthdaysScreenState extends State<BirthdaysScreen> {
  List<Child> _upcomingBirthdays = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUpcomingBirthdays();
  }

  Future<void> _loadUpcomingBirthdays() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final groupsProvider = Provider.of<GroupsProvider>(context, listen: false);
      final currentUser = authProvider.user;
      
      final childrenService = ChildrenService();

      if (currentUser != null && currentUser.role == 'teacher') {
        // Загружаем группы, в которых воспитатель является учителем
        await groupsProvider.loadGroupsByTeacherId(currentUser.id);
        final teacherGroups = groupsProvider.groups;

        // Получаем ID групп, в которых воспитатель является учителем
        List<String> groupIds = teacherGroups.map((group) => group['_id'] ?? group['id']).toList().cast<String>();

        // Загружаем всех детей и фильтруем только тех, кто принадлежит к группам воспитателя
        List<Child> allChildren = await childrenService.getAllChildren();
        List<Child> childrenInTeacherGroups = allChildren.where((child) {
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

        // Фильтруем детей с днями рождения и сортируем по ближайшим
        _upcomingBirthdays = _filterAndSortBirthdays(childrenInTeacherGroups);
      } else {
        // Для других ролей (администратор и т.д.) загружаем всех детей с днями рождения
        List<Child> allChildren = await childrenService.getAllChildren();
        _upcomingBirthdays = _filterAndSortBirthdays(allChildren);
      }
    } catch (e) {
      _errorMessage = 'Ошибка загрузки дней рождения: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
 }

  List<Child> _filterAndSortBirthdays(List<Child> children) {
    final now = DateTime.now();
    final currentYear = now.year;
    
    // Фильтруем детей с датами рождения
    List<Child> childrenWithBirthdays = children.where((child) => child.birthday != null).toList();
    
    // Сортируем по ближайшим дням рождения
    childrenWithBirthdays.sort((child1, child2) {
      DateTime? date1 = _getNextBirthdayDate(child1.birthday, now);
      DateTime? date2 = _getNextBirthdayDate(child2.birthday, now);
      
      if (date1 == null) return 1;
      if (date2 == null) return -1;
      
      return date1.compareTo(date2);
    });
    
    return childrenWithBirthdays;
  }

  DateTime? _getNextBirthdayDate(String? birthdayString, DateTime currentDate) {
    if (birthdayString == null) return null;
    
    try {
      DateTime birthday = DateTime.parse(birthdayString);
      
      // Создаем дату дня рождения в текущем году
      DateTime birthdayThisYear = DateTime(currentDate.year, birthday.month, birthday.day);
      
      // Если день рождения уже прошел в этом году, берем следующий год
      if (birthdayThisYear.isBefore(currentDate)) {
        birthdayThisYear = DateTime(currentDate.year + 1, birthday.month, birthday.day);
      }
      
      return birthdayThisYear;
    } catch (e) {
      return null;
    }
  }

  String _formatBirthdayDate(DateTime date) {
    const List<String> months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    
    int day = date.day;
    int monthIndex = date.month - 1;
    int year = date.year;
    
    return '$day ${months[monthIndex]}, $year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Дни рождения'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : _upcomingBirthdays.isEmpty
                      ? const Center(
                          child: Text('Нет предстоящих дней рождения'),
                        )
                      : ListView.builder(
                          itemCount: _upcomingBirthdays.length,
                          itemBuilder: (context, index) {
                            final child = _upcomingBirthdays[index];
                            final birthdayDate = _getNextBirthdayDate(child.birthday, DateTime.now());
                            
                            return Container(
                              margin: EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    if (child.parentName != null) ...[
                                      Row(
                                        children: [
                                          Icon(Icons.person, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text('Родитель: ${child.parentName}',
                                               style: TextStyle(color: Colors.grey[700])),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    if (birthdayDate != null) ...[
                                      Row(
                                        children: [
                                          Icon(Icons.cake, size: 16, color: Colors.orange),
                                          const SizedBox(width: 4),
                                          Text(
                                            'День рождения: ${_formatBirthdayDate(birthdayDate)}',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (child.groupId != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getChildGroupInfo(child),
                                          style: TextStyle(color: Colors.blue),
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
}