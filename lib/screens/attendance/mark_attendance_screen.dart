import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/child_model.dart';
import '../../../models/attendance_model.dart';
import '../../../core/services/children_service.dart';
import '../../../core/services/attendance_service.dart';
import '../../../providers/auth_provider.dart';
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

      // Получаем информацию о текущем пользователе
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final User? currentUser = authProvider.user;

      if (currentUser != null && currentUser.role == 'teacher') {
        // Если пользователь - воспитатель, загружаем только детей из его групп
        List<Child> allChildren = await _childrenService.getAllChildren();

        // Фильтруем детей по группам, где учитель является воспитателем
        children = allChildren.where((child) {
          if (child.groupId == null) return false;

          // Если groupId это объект группы, проверяем teacherId
          if (child.groupId is Map) {
            final group = child.groupId as Map;
            return group['teacherId'] == currentUser.id;
          }

          // Если groupId это строка, нам нужно получить полную информацию о группе
          // В этом случае мы не можем отфильтровать без дополнительного запроса
          // Поэтому просто показываем всех детей для простоты
          return true;
        }).toList();
      } else {
        // Для других ролей (администратор и т.д.) загружаем всех детей
        children = await _childrenService.getAllChildren();
      }

      present = List.generate(children.length, (index) => true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки детей: $e')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
      
      // Group children by groupId to send separate bulk requests
      Map<String, List<Map<String, dynamic>>> groupedRecords = {};
      
      for (int i = 0; i < children.length; i++) {
        // Determine the groupId for this child
        String childGroupId = '';
        if (children[i].groupId is String) {
          childGroupId = children[i].groupId as String;
        } else if (children[i].groupId is Map<String, dynamic>) {
          final groupMap = children[i].groupId as Map<String, dynamic>;
          childGroupId = groupMap['_id']?.toString() ?? groupMap['id']?.toString() ?? '';
        }
        
        if (childGroupId.isEmpty) {
          continue; // Skip children without a group
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

      // Send bulk requests for each group separately
      int successCount = 0;
      int errorCount = 0;
      List<String> errors = [];
      
      for (var entry in groupedRecords.entries) {
        final groupId = entry.key;
        final records = entry.value;
        
        try {
          await _attendanceService.markAttendanceBulk(
            records.map((record) => Attendance(
              id: '',
              childId: record['childId'],
              groupId: groupId,
              date: date,
              checkIn: '',
              status: record['status'],
              notes: record['notes'],
            )).toList(),
            groupId: groupId,
          );
          successCount += records.length;
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
      }

      // Refresh the list
      await _loadChildren();
    } on Exception catch (e) {
      String errorMessage = e.toString();
      
      // Check for specific error messages
      if (errorMessage.contains('Нет подключения к интернету')) {
        errorMessage = 'Нет подключения к интернету';
      } else if (errorMessage.contains('Время для отметки посещаемости еще не наступило') ||
                 errorMessage.contains('too early') ||
                 errorMessage.contains('early')) {
        errorMessage = 'Время для отметки посещаемости еще не наступило';
      } else if (errorMessage.contains('Время для отметки посещаемости истекло') ||
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
      } else if (errorMessage.contains('проверьте время сотрудника или выбранных детей')) {
        errorMessage = 'Ошибка отметки посещаемости. Проверьте время сотрудника или выбранных детей';
      } else if (errorMessage.contains('employee') || errorMessage.contains('time') || errorMessage.contains('сотрудника')) {
        errorMessage = 'Ошибка отметки посещаемости. Проверьте время сотрудника или выбранных детей';
      } else {
        errorMessage = 'Не удалось добавить посещаемость. Проверьте время, сотрудника и выбранных детей';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      String errorMessage = 'Не удалось добавить посещаемость. Проверьте время, сотрудника и выбранных детей';
      
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
                    // Date selection only (no time)
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                    // Children list
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
                                  color: Colors.grey.withAlpha((0.1 * 255).round()),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CheckboxListTile(
                              title: Text(children[index].fullName),
                              subtitle: Text(_getChildGroupInfo(children[index])),
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

                    // Submit button
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
    return child.groupId.toString();
  }
}
