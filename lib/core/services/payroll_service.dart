import '../../models/payroll_model.dart';
import 'api_service.dart';

class PayrollService {
  final ApiService _apiService = ApiService();

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
        print('DEBUG PAYROLL DATA: $data');
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
}
