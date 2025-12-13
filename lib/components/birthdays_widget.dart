import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/child_model.dart';
import '../models/group_model.dart';
import '../core/services/children_service.dart';
import '../providers/groups_provider.dart';
import '../screens/birthdays/birthdays_screen.dart';


class BirthdaysWidget extends StatefulWidget {
  const BirthdaysWidget({super.key});

  @override
  State<BirthdaysWidget> createState() => _BirthdaysWidgetState();
}

class _BirthdaysWidgetState extends State<BirthdaysWidget> {
  Child? _nextBirthdayChild;
  String? _nextBirthdayGroupName;
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

      final childrenService = ChildrenService();
      
      // Загружаем всех детей с днями рождения для всех сотрудников (без фильтрации по группам)
      // Бэкенд делает .populate('groupId'), поэтому groupName будет доступен в child.groupName
      List<Child> allChildren = await childrenService.getAllChildren();
      print('BirthdaysWidget | Children loaded: ${allChildren.length}');
      
      if (mounted) {
        Child? nextChild = _getNextBirthdayChild(allChildren);
        String? groupName;
        
        // Get group name directly from the child object (populated from backend)
        if (nextChild != null) {
          print('BirthdaysWidget | Next birthday: ${nextChild.fullName}, groupId=${nextChild.groupId}, groupName=${nextChild.groupName}');
          groupName = nextChild.groupName;
        }
        
        setState(() {
          _nextBirthdayChild = nextChild;
          _nextBirthdayGroupName = groupName;
        });
      }
    } catch (e) {


      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки дней рождения: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Child? _getNextBirthdayChild(List<Child> children) {
    final now = DateTime.now();

    // Фильтруем детей с датами рождения
    List<Child> childrenWithBirthdays =
        children.where((child) => child.birthday != null).toList();

    if (childrenWithBirthdays.isEmpty) {
      return null;
    }

    // Сортируем по ближайшим дням рождения
    childrenWithBirthdays.sort((child1, child2) {
      DateTime? date1 = _getNextBirthdayDate(child1.birthday, now);
      DateTime? date2 = _getNextBirthdayDate(child2.birthday, now);

      if (date1 == null) return 1;
      if (date2 == null) return -1;

      return date1.compareTo(date2);
    });

    // Возвращаем только самого ближайшего ребенка с днем рождения
    return childrenWithBirthdays.first;
  }

  DateTime? _getNextBirthdayDate(String? birthdayString, DateTime currentDate) {
    if (birthdayString == null) return null;

    try {
      DateTime birthday = DateTime.parse(birthdayString);

      // Создаем дату дня рождения в текущем году
      DateTime birthdayThisYear =
          DateTime(currentDate.year, birthday.month, birthday.day);

      // Если день рождения уже прошел в этом году, берем следующий год
      if (birthdayThisYear.isBefore(currentDate)) {
        birthdayThisYear =
            DateTime(currentDate.year + 1, birthday.month, birthday.day);
      }

      return birthdayThisYear;
    } catch (e) {
      return null;
    }
  }

  String _formatBirthdayDate(DateTime date) {
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
  }
 
  int? _calculateAge(String? birthdayString, DateTime currentDate) {
    if (birthdayString == null) return null;
    
    try {
      DateTime birthday = DateTime.parse(birthdayString);
      DateTime? nextBirthday = _getNextBirthdayDate(birthdayString, currentDate);
      
      if (nextBirthday != null) {
        // Calculate age based on the next birthday
        int years = nextBirthday.year - birthday.year;
        return years;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
 
  String _getAgeSuffix(int age) {
    if (age % 10 == 1 && age % 100 != 11) {
      return 'год';
    } else if ((age % 10 >= 2 && age % 10 <= 4) && (age % 100 < 10 || age % 100 >= 20)) {
      return 'года';
    } else {
      return 'лет';
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cake, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Предстоящие дни рождения',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_errorMessage!,
                    style: const TextStyle(color: Colors.red)),
              )
            else if (_nextBirthdayChild == null)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'Нет предстоящих дней рождения',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              InkWell(
                onTap: () {
                  // Навигация к полному списку дней рождения
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BirthdaysScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nextBirthdayChild!.fullName,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                            if (_nextBirthdayGroupName != null)
                              Text(
                                'Группа: $_nextBirthdayGroupName',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            Text(
                              'Следующий день рождения: ${_formatBirthdayDate(_getNextBirthdayDate(_nextBirthdayChild!.birthday, DateTime.now())!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Исполняется: ${_calculateAge(_nextBirthdayChild!.birthday, DateTime.now()) ?? 0} ${_getAgeSuffix(_calculateAge(_nextBirthdayChild!.birthday, DateTime.now()) ?? 0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
