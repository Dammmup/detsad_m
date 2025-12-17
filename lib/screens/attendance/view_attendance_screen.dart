import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/attendance_record_model.dart';
import '../../../core/services/attendance_service.dart';

class ViewAttendanceScreen extends StatefulWidget {
  const ViewAttendanceScreen({super.key});

  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  List<AttendanceRecord> attendanceRecords = [];
  bool isLoading = true;
  DateTime selectedDate = DateTime.now();
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    try {
      setState(() {
        isLoading = true;
      });

      String date = DateFormat('yyyy-MM-dd').format(selectedDate);
      attendanceRecords = await _attendanceService.getAttendanceRecords(date);
    } on Exception catch (e) {
      String errorMessage = e.toString();

      if (errorMessage.contains('Нет подключения к интернету')) {
        errorMessage = 'Нет подключения к интернету';
      } else if (errorMessage.contains('Нет прав для просмотра') ||
          errorMessage.contains('unauthorized') ||
          errorMessage.contains('403')) {
        errorMessage = 'Нет прав для просмотра посещаемости на эту дату';
      } else if (errorMessage.contains('Дата не указана') ||
          errorMessage.contains('date required') ||
          errorMessage.contains('invalid date')) {
        errorMessage = 'Некорректная дата для просмотра посещаемости';
      } else if (errorMessage.contains('404')) {
        attendanceRecords = [];
        return;
      } else {
        errorMessage =
            'Ошибка загрузки посещаемости. Проверьте подключение к интернету';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      String errorMessage =
          'Ошибка загрузки посещаемости. Проверьте подключение к интернету';

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
      await _loadAttendance();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'early_departure':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'present':
        return 'Присутствует';
      case 'absent':
        return 'Отсутствует';
      case 'late':
        return 'Опоздание';
      case 'early_departure':
        return 'Ранний уход';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Посещаемость'),
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
                        child: InkWell(
                          onTap: _selectDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      color: Colors.blue),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Выбранная дата',
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey)),
                                      Text(
                                          DateFormat('dd.MM.yyyy')
                                              .format(selectedDate),
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ],
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Записи посещаемости',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: attendanceRecords.isEmpty
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
                                    Icon(Icons.visibility_off,
                                        size: 48, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'Нет записей посещаемости на выбранную дату',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: attendanceRecords.length,
                              itemBuilder: (context, index) {
                                final record = attendanceRecords[index];

                                String childName = record.child.fullName;
                                String childGroup = record.child.groupId is Map
                                    ? (record.child.groupId as Map)['name'] ??
                                        'Группа не указана'
                                    : 'Группа не указана';

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
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                childName,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey[800]),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                    record.status),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                _getStatusText(record.status),
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          childGroup,
                                          style: TextStyle(
                                              color: Colors.grey[600]),
                                        ),
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
}
