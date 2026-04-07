import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/services/payroll_service.dart';
import '../models/payroll_model.dart';
import '../core/utils/logger.dart';
import 'package:intl/intl.dart';

class PayrollProvider with ChangeNotifier {
  final PayrollService _payrollService = PayrollService();

  List<Payroll> _payrolls = [];
  Payroll? _currentPayroll;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _currentDate = tz.TZDateTime.now(tz.getLocation('Asia/Almaty'));

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
          await loadPayrollDetails(_currentPayroll!.id!);
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

  Future<void> loadAllPayrolls() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final period = currentPeriod;
      final result = await _payrollService.getAllPayrolls(period: period);
      _payrolls = result;
      _currentPayroll = null; // В режиме списка мы не выбираем одну зарплату сразу
    } catch (e) {
      _errorMessage = e.toString();
      _payrolls = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPayrollDetails(String payrollId) async {
    try {
      final detailedPayroll = await _payrollService.getPayrollWithShiftDetails(payrollId);
      _currentPayroll = detailedPayroll;
      notifyListeners();
    } catch (e) {
      AppLogger.warning('Could not load shift details: $e');
    }
  }

  void selectPayroll(Payroll payroll) {
    _currentPayroll = payroll;
    if (payroll.id != null) {
      loadPayrollDetails(payroll.id!);
    }
    notifyListeners();
  }

  void clearSelection() {
    _currentPayroll = null;
    notifyListeners();
  }

  void prevMonth(bool isAdmin) {
    _currentDate = DateTime(_currentDate.year, _currentDate.month - 1);
    if (isAdmin) {
      loadAllPayrolls();
    } else {
      loadMyPayroll();
    }
  }

  void nextMonth(bool isAdmin) {
    _currentDate = DateTime(_currentDate.year, _currentDate.month + 1);
    if (isAdmin) {
      loadAllPayrolls();
    } else {
      loadMyPayroll();
    }
  }

  void setCurrentDate(DateTime date, bool isAdmin) {
    _currentDate = date;
    if (isAdmin) {
      loadAllPayrolls();
    } else {
      loadMyPayroll();
    }
  }

  Future<void> addFine(String payrollId, double amount, String reason) async {
    try {
      await _payrollService.addFine(payrollId, amount, reason);
      await loadPayrollDetails(payrollId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteFine(String payrollId, String fineId) async {
    try {
      await _payrollService.deleteFine(payrollId, fineId);
      await loadPayrollDetails(payrollId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateStatus(String payrollId, String status) async {
    try {
      await _payrollService.updatePayrollStatus(payrollId, status);
      if (_currentPayroll?.id == payrollId) {
        await loadPayrollDetails(payrollId);
      } else {
        await loadAllPayrolls();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePayroll(String payrollId) async {
    try {
      await _payrollService.deletePayroll(payrollId);
      _payrolls.removeWhere((p) => p.id == payrollId);
      if (_currentPayroll?.id == payrollId) {
        _currentPayroll = null;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
