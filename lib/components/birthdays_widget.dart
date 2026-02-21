import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_decorations.dart';
import '../models/child_model.dart';
import '../core/services/children_service.dart';
import '../core/utils/logger.dart';
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

      List<Child> allChildren = await childrenService.getAllChildren();
      AppLogger.debug('BirthdaysWidget | Children loaded: ${allChildren.length}');

      if (mounted) {
        Child? nextChild = _getNextBirthdayChild(allChildren);
        String? groupName;

        if (nextChild != null) {
          AppLogger.debug(
              'BirthdaysWidget | Next birthday: ${nextChild.fullName}, groupId=${nextChild.groupId}, groupName=${nextChild.groupName}');
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

    List<Child> childrenWithBirthdays =
        children.where((child) => child.birthday != null).toList();

    if (childrenWithBirthdays.isEmpty) {
      return null;
    }

    childrenWithBirthdays.sort((child1, child2) {
      DateTime? date1 = _getNextBirthdayDate(child1.birthday, now);
      DateTime? date2 = _getNextBirthdayDate(child2.birthday, now);

      if (date1 == null) return 1;
      if (date2 == null) return -1;

      return date1.compareTo(date2);
    });

    return childrenWithBirthdays.first;
  }

  DateTime? _getNextBirthdayDate(String? birthdayString, DateTime currentDate) {
    if (birthdayString == null) return null;

    try {
      DateTime birthday = DateTime.parse(birthdayString);

      DateTime birthdayThisYear =
          DateTime(currentDate.year, birthday.month, birthday.day);

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
      DateTime? nextBirthday =
          _getNextBirthdayDate(birthdayString, currentDate);

      if (nextBirthday != null) {
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
    } else if ((age % 10 >= 2 && age % 10 <= 4) &&
        (age % 100 < 10 || age % 100 >= 20)) {
      return 'года';
    } else {
      return 'лет';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cake, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Предстоящие дни рождения',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey600,
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
                    style: const TextStyle(color: AppColors.error)),
              )
            else if (_nextBirthdayChild == null)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'Нет предстоящих дней рождения',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              InkWell(
                onTap: () {
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
                          color: AppColors.primary,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.grey600,
                              ),
                            ),
                            if (_nextBirthdayGroupName != null)
                              Text(
                                'Группа: $_nextBirthdayGroupName',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            Text(
                              'Следующий день рождения: ${_formatBirthdayDate(_getNextBirthdayDate(_nextBirthdayChild!.birthday, DateTime.now())!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              'Исполняется: ${_calculateAge(_nextBirthdayChild!.birthday, DateTime.now()) ?? 0} ${_getAgeSuffix(_calculateAge(_nextBirthdayChild!.birthday, DateTime.now()) ?? 0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textSecondary,
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
