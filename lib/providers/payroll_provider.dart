import 'package:flutter/material.dart';
import '../core/services/payroll_service.dart';
import '../models/payroll_model.dart';
import 'package:intl/intl.dart';

class PayrollProvider with ChangeNotifier {
  final PayrollService _payrollService = PayrollService();

  List<Payroll> _payrolls = [];
  Payroll? _currentPayroll;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _currentDate = DateTime.now();

  List<Payroll> get payrolls => _payrolls;
  Payroll? get currentPayroll => _currentPayroll;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get currentDate => _currentDate;

  String get currentPeriod => DateFormat('yyyy-MM').format(_currentDate);

  Future<void> loadMyPayroll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final period = currentPeriod;
      final result = await _payrollService.getMyPayrolls(period: period);
      _payrolls = result;

      if (result.isNotEmpty) {
        _currentPayroll = result.first;

        if (_currentPayroll?.id != null) {
          try {
            final detailedPayroll = await _payrollService
                .getPayrollWithShiftDetails(_currentPayroll!.id!);
            _currentPayroll = detailedPayroll;
          } catch (e) {
            print('Could not load shift details: $e');
          }
        }
      } else {
        _currentPayroll = null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _currentPayroll = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void prevMonth() {
    _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
    loadMyPayroll();
  }

  void nextMonth() {
    _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
    loadMyPayroll();
  }

  void setCurrentDate(DateTime date) {
    _currentDate = date;
    loadMyPayroll();
  }
}
