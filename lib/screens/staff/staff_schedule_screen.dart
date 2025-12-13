import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Добавляем импорт для инициализации локали
import '../../providers/auth_provider.dart';
import '../../core/services/shifts_service.dart';

class StaffScheduleScreen extends StatefulWidget {
  const StaffScheduleScreen({super.key});

  @override
  State<StaffScheduleScreen> createState() => _StaffScheduleScreenState();
}

class _StaffScheduleScreenState extends State<StaffScheduleScreen> {
  DateTime _currentMonth = DateTime.now();
  final ShiftsService _shiftsService = ShiftsService();
  List<dynamic> _shifts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting(
        'ru_RU'); // Инициализация локали для форматирования дат
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user != null) {
        // Format the month range
        String startDate = DateFormat('yyyy-MM-01').format(_currentMonth);
        String endDate = DateFormat('yyyy-MM-dd').format(DateTime(
          _currentMonth.year,
          _currentMonth.month + 1,
          0, // Last day of the month
        ));

        // Load shifts for the current user in the selected month
        List<dynamic> scheduledShifts = await _shiftsService.getStaffShifts(
          staffId: user.id,
          startDate: startDate,
          endDate: endDate,
        );

        // Load attendance tracking records for the same period
        List<dynamic> attendanceRecords = await _shiftsService.getStaffAttendanceTrackingRecords(
          staffId: user.id,
          startDate: startDate,
          endDate: endDate,
        );

        // Combine shift data with attendance data based on date
        _shifts = _combineShiftAndAttendanceData(scheduledShifts, attendanceRecords);

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Пользователь не авторизован';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки графика: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _loadSchedule();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _loadSchedule();
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'scheduled':
        return 'Запланирована';
      case 'in_progress':
        return 'В процессе';
      case 'completed':
        return 'Завершена';
      case 'late':
        return 'Опоздание';
      case 'pending_approval':
        return 'Ожидает подтверждения';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'late':
        return Colors.red;
      case 'pending_approval':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой график'),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month navigation
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _previousMonth,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        DateFormat('MMMM yyyy', 'ru_RU').format(_currentMonth),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _nextMonth,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // User info
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
                        'Сотрудник: ${user?.firstName ?? ''} ${user?.lastName ?? ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Роль: ${user?.role ?? ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Schedule list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
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
                                  const Icon(Icons.error_outline,
                                      size: 48, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _shifts.isEmpty
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
                                      const Icon(Icons.schedule,
                                          size: 48, color: Colors.grey),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Нет смен в выбранном месяце',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 16),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Период: ${DateFormat('dd.MM.yyyy').format(DateTime(_currentMonth.year, _currentMonth.month, 1))} - ${DateFormat('dd.MM.yyyy').format(DateTime(_currentMonth.year, _currentMonth.month + 1, 0))}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _shifts.length,
                                itemBuilder: (context, index) {
                                  final shift = _shifts[index];

                                  // Parse date
                                  DateTime shiftDate;
                                  if (shift['date'] is String) {
                                    shiftDate = DateTime.parse(shift['date']);
                                  } else if (shift['date'] is DateTime) {
                                    shiftDate = shift['date'];
                                  } else {
                                    shiftDate = DateTime.now();
                                  }

                                  // Format time - используем отмеченное время прихода и ухода, если доступно
                                  String scheduledStartTime =
                                      shift['startTime'] ?? '0:00';
                                  String scheduledEndTime =
                                      shift['endTime'] ?? '00:00';
                                  String? actualStartTime = shift[
                                      'actualStartTime']; // отмеченное время прихода
                                  String? actualEndTime = shift[
                                      'actualEndTime']; // отмеченное время ухода

                                  // Если есть отмеченное время, используем его, иначе запланированное
                                  String displayStartTime = actualStartTime ?? scheduledStartTime;
                                  String displayEndTime = actualEndTime ?? scheduledEndTime;

                                  // Определяем, было ли время отмечено (отличается от запланированного)
                                  bool hasActualTimes = (actualStartTime != null && actualStartTime != scheduledStartTime) ||
                                                        (actualEndTime != null && actualEndTime != scheduledEndTime);

                                  // Проверяем, есть ли отмеченное время вообще (для отображения секции "Отмечено")
                                  bool hasAnyActualTime = actualStartTime != null || actualEndTime != null;

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
                                              Text(
                                                DateFormat(
                                                        'dd MMMM yyyy', 'ru_RU')
                                                    .format(shiftDate),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(
                                                      shift['status'] ??
                                                          'scheduled'),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  _getStatusText(
                                                      shift['status'] ??
                                                          'scheduled'),
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Отображаем запланированное время
                                          Row(
                                            children: [
                                              const Icon(Icons.schedule,
                                                  size: 16, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Запланировано: $scheduledStartTime - $scheduledEndTime',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  decoration: hasActualTimes
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                                  decorationColor:
                                                      Colors.grey[400],
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Отображаем отмеченное время, если оно было зафиксировано
                                          if (hasAnyActualTime) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.access_time,
                                                    size: 16,
                                                    color: Colors.blue),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Отмечено: $displayStartTime - $displayEndTime',
                                                  style: const TextStyle(
                                                    color: Colors.blue,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (shift['notes'] != null &&
                                              shift['notes'].isNotEmpty)
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.note,
                                                        size: 16,
                                                        color: Colors.grey),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        'Примечание: ${shift['notes']}',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
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

  // Method to combine shift data with attendance tracking data
  List<dynamic> _combineShiftAndAttendanceData(List<dynamic> scheduledShifts, List<dynamic> attendanceRecords) {
    print('StaffScheduleScreen | Combining ${scheduledShifts.length} shifts with ${attendanceRecords.length} attendance records');
    
    // Create a map of attendance records by date for quick lookup
    Map<String, dynamic> attendanceMap = {};
    for (var record in attendanceRecords) {
      // Convert date to string format for comparison
      String dateStr;
      if (record['date'] is String) {
        dateStr = DateTime.parse(record['date']).toIso8601String().split('T')[0];
      } else if (record['date'] is DateTime) {
        dateStr = (record['date'] as DateTime).toIso8601String().split('T')[0];
      } else {
        continue; // Skip invalid records
      }
      attendanceMap[dateStr] = record;
      print('StaffScheduleScreen | Attendance map: $dateStr -> actualStart=${record['actualStart']}, actualEnd=${record['actualEnd']}');
    }

    // Process each scheduled shift and enrich with attendance data if available
    List<dynamic> combinedShifts = [];
    for (var shift in scheduledShifts) {
      String shiftDateStr;
      if (shift['date'] is String) {
        shiftDateStr = DateTime.parse(shift['date']).toIso8601String().split('T')[0];
      } else if (shift['date'] is DateTime) {
        shiftDateStr = (shift['date'] as DateTime).toIso8601String().split('T')[0];
      } else {
        combinedShifts.add(shift);
        continue; // Keep original shift if date is invalid
      }

      // Check if there's attendance record for this date
      if (attendanceMap.containsKey(shiftDateStr)) {
        var attendanceRecord = attendanceMap[shiftDateStr];
        // Merge the shift data with attendance data
        var combinedShift = Map<String, dynamic>.from(shift);
        
        // Format actualStart and actualEnd from ISO datetime to HH:mm time string
        String? actualStartTime = _formatISOToTimeString(attendanceRecord['actualStart']);
        String? actualEndTime = _formatISOToTimeString(attendanceRecord['actualEnd']);
        
        print('StaffScheduleScreen | Shift $shiftDateStr: actualStart=$actualStartTime, actualEnd=$actualEndTime');
        
        combinedShift['actualStartTime'] = actualStartTime;
        combinedShift['actualEndTime'] = actualEndTime;
        combinedShift['actualStart'] = attendanceRecord['actualStart'];
        combinedShift['actualEnd'] = attendanceRecord['actualEnd'];
        combinedShift['workDuration'] = attendanceRecord['workDuration'];
        combinedShift['breakDuration'] = attendanceRecord['breakDuration'];
        combinedShift['overtimeDuration'] = attendanceRecord['overtimeDuration'];
        combinedShift['lateMinutes'] = attendanceRecord['lateMinutes'];
        combinedShift['earlyLeaveMinutes'] = attendanceRecord['earlyLeaveMinutes'];
        combinedShift['penalties'] = attendanceRecord['penalties'];
        combinedShift['bonuses'] = attendanceRecord['bonuses'];
        combinedShift['notes'] = attendanceRecord['notes'] ?? shift['notes'];
        combinedShift['totalHours'] = attendanceRecord['totalHours'];
        combinedShift['regularHours'] = attendanceRecord['regularHours'];
        combinedShift['overtimeHours'] = attendanceRecord['overtimeHours'];
        combinedShifts.add(combinedShift);
      } else {
        // If no attendance record, keep the scheduled shift as is
        combinedShifts.add(shift);
      }
    }

    // Sort the combined shifts by date
    combinedShifts.sort((a, b) {
      DateTime dateA, dateB;
      if (a['date'] is String) {
        dateA = DateTime.parse(a['date']);
      } else {
        dateA = a['date'];
      }
      if (b['date'] is String) {
        dateB = DateTime.parse(b['date']);
      } else {
        dateB = b['date'];
      }
      return dateB.compareTo(dateA); // Sort in descending order (newest first)
    });

    return combinedShifts;
  }
  
  // Helper function to format ISO datetime string to HH:mm time string
  String? _formatISOToTimeString(dynamic isoDateTime) {
    if (isoDateTime == null) return null;
    
    try {
      if (isoDateTime is String) {
        // Parse ISO datetime and format to HH:mm
        DateTime dateTime = DateTime.parse(isoDateTime);
        return DateFormat('HH:mm').format(dateTime);
      } else if (isoDateTime is DateTime) {
        return DateFormat('HH:mm').format(isoDateTime);
      }
    } catch (e) {
      print('StaffScheduleScreen | Error formatting time: $e');
    }
    
    // If it's already a time string like "08:30", return as is
    return isoDateTime.toString();
  }
}

