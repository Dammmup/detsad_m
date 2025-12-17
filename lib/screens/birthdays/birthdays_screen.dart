import 'package:flutter/material.dart';
import '../../models/child_model.dart';
import '../../core/services/children_service.dart';

class BirthdaysScreen extends StatefulWidget {
  const BirthdaysScreen({super.key});

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

      final childrenService = ChildrenService();

      List<Child> allChildren = await childrenService.getAllChildren();

      if (mounted) {
        setState(() {
          _upcomingBirthdays = _filterAndSortBirthdays(allChildren);
        });
      }
    } on Exception catch (e) {
      String errorMessage = e.toString();

      if (errorMessage.contains('Нет подключения к интернету')) {
        errorMessage = 'Нет подключения к интернету';
      } else if (errorMessage.contains('Нет прав для просмотра') ||
          errorMessage.contains('unauthorized') ||
          errorMessage.contains('403')) {
        errorMessage = 'Нет прав для просмотра дней рождения детей';
      } else if (errorMessage.contains('Данные не найдены') ||
          errorMessage.contains('not found') ||
          errorMessage.contains('404')) {
        errorMessage = 'Данные о детях не найдены';
      } else {
        errorMessage =
            'Ошибка загрузки дней рождения. Проверьте подключение к интернету';
      }

      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      String errorMessage =
          'Ошибка загрузки дней рождения. Проверьте подключение к интернету';

      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
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

  List<Child> _filterAndSortBirthdays(List<Child> children) {
    final now = DateTime.now();

    List<Child> childrenWithBirthdays =
        children.where((child) => child.birthday != null).toList();

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Дни рождения'),
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
                      : RefreshIndicator(
                          onRefresh: () => _loadUpcomingBirthdays(),
                          child: ListView.builder(
                            itemCount: _upcomingBirthdays.length,
                            itemBuilder: (context, index) {
                              final child = _upcomingBirthdays[index];
                              final birthdayDate = _getNextBirthdayDate(
                                  child.birthday, DateTime.now());

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
                                      if (birthdayDate != null) ...[
                                        Row(
                                          children: [
                                            const Icon(Icons.cake,
                                                size: 16, color: Colors.orange),
                                            const SizedBox(width: 4),
                                            Text(
                                              'День рождения: ${_formatBirthdayDate(birthdayDate)}',
                                              style: const TextStyle(
                                                color: Colors.orange,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.cake,
                                                size: 16, color: Colors.blue),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Исполняется: ${_calculateAge(child.birthday, DateTime.now()) ?? 0} ${_getAgeSuffix(_calculateAge(child.birthday, DateTime.now()) ?? 0)}',
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w500,
                                              ),
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
                                            color: Colors.blue
                                                .withAlpha((0.1 * 255).round()),
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
        ),
      ),
    );
  }

  String _getChildGroupInfo(Child child) {
    if (child.groupName != null && child.groupName!.isNotEmpty) {
      return 'Группа: ${child.groupName}';
    }

    if (child.groupId == null) {
      return 'Группа не указана';
    }

    return 'Группа: ${child.groupId}';
  }
}
