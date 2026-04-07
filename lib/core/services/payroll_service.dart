import '../../models/payroll_model.dart';
import 'api_service.dart';
import '../utils/logger.dart';

class PayrollService {
  final ApiService _apiService = ApiService();

  Future<List<Payroll>> getAllPayrolls({String? period}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null) queryParams['period'] = period;

      final response = await _apiService.get(
        '/payroll',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Payroll.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load all payrolls');
      }
    } catch (e) {
      throw Exception('Error fetching all payrolls: $e');
    }
  }

  Future<List<Payroll>> getMyPayrolls({String? period, String? month}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (period != null) queryParams['period'] = period;
      if (month != null) queryParams['month'] = month;

      final response = await _apiService.get(
        '/payroll/my',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        AppLogger.debug('DEBUG PAYROLL DATA: $data');
        return data.map((json) => Payroll.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load payrolls');
      }
    } catch (e) {
      throw Exception('Error fetching payrolls: $e');
    }
  }

  Future<Payroll> getPayrollWithShiftDetails(String payrollId) async {
    try {
      final response = await _apiService.get('/payroll/$payrollId');
      if (response.statusCode == 200) {
        return Payroll.fromJson(response.data);
      } else {
        throw Exception('Failed to load payroll details');
      }
    } catch (e) {
      throw Exception('Error fetching payroll details: $e');
    }
  }

  Future<void> addFine(String payrollId, double amount, String reason) async {
    try {
      await _apiService.post('/payroll/$payrollId/fines', data: {
        'amount': amount,
        'reason': reason,
      });
    } catch (e) {
      throw Exception('Error adding fine: $e');
    }
  }

  Future<void> deleteFine(String payrollId, String fineId) async {
    try {
      await _apiService.delete('/payroll/$payrollId/fines/$fineId');
    } catch (e) {
      throw Exception('Error deleting fine: $e');
    }
  }

  Future<void> updatePayrollStatus(String payrollId, String status) async {
    try {
      await _apiService.patch('/payroll/$payrollId', data: {
        'status': status,
      });
    } catch (e) {
      throw Exception('Error updating payroll status: $e');
    }
  }

  Future<void> deletePayroll(String payrollId) async {
    try {
      await _apiService.delete('/payroll/$payrollId');
    } catch (e) {
      throw Exception('Error deleting payroll: $e');
    }
  }
}
