import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/child_model.dart';
import '../../../models/attendance_model.dart';
import '../../../core/services/children_service.dart';
import '../../../core/services/attendance_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/groups_provider.dart';
import '../../../models/user_model.dart';
import 'package:provider/provider.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  List<Child> children = [];
  List<bool> present = [];
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();
  String? selectedGroupId;
  final ChildrenService _childrenService = ChildrenService();
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      setState(() {
        isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final User? currentUser = authProvider.user;
      final groupsProvider =
          Provider.of<GroupsProvider>(context, listen: false);

      await groupsProvider.loadGroups();
      final allGroups = groupsProvider.groups;

      print('MarkAttendanceScreen | Loaded ${allGroups.length} groups');
      print('MarkAttendanceScreen | Current user ID: ${currentUser?.id}');
      print('MarkAttendanceScreen | Current user role: ${currentUser?.role}');
      for (var group in allGroups) {
        print(
            'MarkAttendanceScreen | Group: ${group.name}, teacher: ${group.teacher}, id: ${group.id}');
      }

      List<Child> fetchedChildren;
      if (currentUser != null &&
          (currentUser.role == 'teacher' || currentUser.role == 'substitute')) {
        final teacherGroups = allGroups
            .where((group) => group.teacher == currentUser.id)
            .toList();
        print(
            'MarkAttendanceScreen | Teacher groups found: ${teacherGroups.length}');
        for (var group in teacherGroups) {
          print('MarkAttendanceScreen | Teacher group: ${group.name}');
        }

        if (teacherGroups.isNotEmpty) {
          List<Child> teacherChildren = [];
          for (var group in teacherGroups) {
            List<Child> childrenInGroup =
                await _childrenService.getChildrenByGroupId(group.id);
            print(
                'MarkAttendanceScreen | Children in group ${group.name}: ${childrenInGroup.length}');
            teacherChildren.addAll(childrenInGroup);
          }
          fetchedChildren = teacherChildren;
          print(
              'MarkAttendanceScreen | Total children for teacher: ${fetchedChildren.length}');
        } else {
          fetchedChildren = [];
        }
      } else {
        fetchedChildren = await _childrenService.getAllChildren();
      }

      String date = DateFormat('yyyy-MM-dd').format(selectedDate);
      List<Attendance> todaysAttendance =
          await _attendanceService.getAttendanceByDate(date);

      setState(() {
        children = fetchedChildren;
        present = List.generate(children.length, (index) {
          final childId = children[index].id;

          final attendanceRecord = todaysAttendance.firstWhere(
            (att) => att.childId == childId || att.userId == childId,
            orElse: () => Attendance(
              id: '',
              childId: childId,
              groupId: children[index].groupId is String
                  ? children[index].groupId as String
                  : (children[index].groupId is Map
                      ? (children[index].groupId as Map)['_id']?.toString() ??
                          (children[index].groupId as Map)['id']?.toString() ??
                          ''
                      : ''),
              date: date,
              checkIn: '',
              status: 'absent',
            ),
          );
          return attendanceRecord.status == 'present';
        });
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateLocalAttendanceState() async {
    try {
      String date = DateFormat('yyyy-MM-dd').format(selectedDate);
      List<Attendance> todaysAttendance =
          await _attendanceService.getAttendanceByDate(date);

      setState(() {
        present = List.generate(children.length, (index) {
          final childId = children[index].id;
          final attendanceRecord = todaysAttendance.firstWhere(
            (att) => att.childId == childId,
            orElse: () => Attendance(
                id: '',
                childId: '',
                groupId: '',
                date: DateTime.now().toString(),
                checkIn: '',
                status: 'present',
                notes: '',
                markedBy: ''),
          );
          return attendanceRecord.status == 'present';
        });
      });
    } catch (e) {}
  }

  Future<void> _markAttendance() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пользователь не авторизован')),
        );
      }
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      String date = DateFormat('yyyy-MM-dd').format(selectedDate);

      Map<String, List<Map<String, dynamic>>> groupedRecords = {};

      for (int i = 0; i < children.length; i++) {
        String childGroupId = '';
        if (children[i].groupId is String) {
          childGroupId = children[i].groupId as String;
        } else if (children[i].groupId is Map<String, dynamic>) {
          final groupMap = children[i].groupId as Map<String, dynamic>;
          childGroupId =
              groupMap['_id']?.toString() ?? groupMap['id']?.toString() ?? '';
        }

        if (childGroupId.isEmpty) {
          continue;
        }

        if (!groupedRecords.containsKey(childGroupId)) {
          groupedRecords[childGroupId] = [];
        }

        groupedRecords[childGroupId]!.add({
          'childId': children[i].id,
          'groupId': childGroupId,
          'date': date,
          'status': present[i] ? 'present' : 'absent',
          'notes': 'Отметка от мобильного приложения',
        });
      }

      if (groupedRecords.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Не выбраны дети для отметки посещаемости')),
          );
        }
        return;
      }

      int errorCount = 0;
      List<String> errors = [];

      for (var entry in groupedRecords.entries) {
        final groupId = entry.key;
        final records = entry.value;

        try {
          await _attendanceService.markAttendanceBulk(
            records
                .map((record) => Attendance(
                      id: '',
                      childId: record['childId'],
                      groupId: groupId,
                      date: date,
                      checkIn: record['status'] == 'present'
                          ? DateFormat('HH:mm').format(DateTime.now())
                          : '',
                      status: record['status'],
                      notes: record['notes'],
                    ))
                .toList(),
            groupId: groupId,
          );
        } catch (e) {
          errorCount += records.length;
          errors.add('Ошибка для группы $groupId: ${e.toString()}');
        }
      }

      if (errorCount > 0) {
        throw Exception(errors.join('; '));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Посещаемость успешно отмечена')),
        );
        await _updateLocalAttendanceState();
      }

      await _loadChildren();
    } on Exception catch (e) {
      String errorMessage = e.toString();

      if (errorMessage.contains('Нет подключения к интернету')) {
        errorMessage = 'Нет подключения к интернету';
      } else if (errorMessage
              .contains('Время для отметки посещаемости еще не наступило') ||
          errorMessage.contains('too early') ||
          errorMessage.contains('early')) {
        errorMessage = 'Время для отметки посещаемости еще не наступило';
      } else if (errorMessage
              .contains('Время для отметки посещаемости истекло') ||
          errorMessage.contains('too late') ||
          errorMessage.contains('late')) {
        errorMessage = 'Время для отметки посещаемости истекло';
      } else if (errorMessage.contains('Неправильный сотрудник') ||
          errorMessage.contains('invalid employee') ||
          errorMessage.contains('unauthorized')) {
        errorMessage = 'Неправильный сотрудник для отметки посещаемости';
      } else if (errorMessage.contains('Дети не выбраны') ||
          errorMessage.contains('no children') ||
          errorMessage.contains('no selected')) {
        errorMessage = 'Не выбраны дети для отметки посещаемости';
      } else if (errorMessage
          .contains('проверьте время сотрудника или выбранных детей')) {
        errorMessage =
            'Ошибка отметки посещаемости. Проверьте время сотрудника или выбранных детей';
      } else if (errorMessage.contains('employee') ||
          errorMessage.contains('time') ||
          errorMessage.contains('сотрудника')) {
        errorMessage =
            'Ошибка отметки посещаемости. Проверьте время сотрудника или выбранных детей';
      } else {
        errorMessage =
            'Не удалось добавить посещаемость. Проверьте время, сотрудника и выбранных детей';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      String errorMessage =
          'Не удалось добавить посещаемость. Проверьте время, сотрудника и выбранных детей';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отметить посещаемость'),
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
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
                            Text(
                              'Дата',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800]),
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.calendar_today,
                                            color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('Выбрать дату',
                                            style: TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                    Text(
                                        DateFormat('dd.MM.yyyy')
                                            .format(selectedDate),
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Дети',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: children.length,
                        itemBuilder: (context, index) {
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
                            child: CheckboxListTile(
                              title: Text(children[index].fullName),
                              subtitle:
                                  Text(_getChildGroupInfo(children[index])),
                              value: present[index],
                              onChanged: (value) {
                                setState(() {
                                  present[index] = value ?? false;
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _markAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Отметить посещаемость',
                            style: TextStyle(fontSize: 16)),
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
}
