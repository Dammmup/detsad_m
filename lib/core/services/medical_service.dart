import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../../models/medical_record.dart';
import '../utils/logger.dart';

class MedicalService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Future<List<MedicalRecord>> getMedicalRecords({
    required String childId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/medical/records',
        queryParameters: {
          'childId': childId,
          'startDate': startDate,
          'endDate': endDate,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) => MedicalRecord.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load medical records');
      }
    } catch (e) {
      AppLogger.error('MedicalService | Error fetching medical records: $e');
      rethrow;
    }
  }

  Future<MedicalRecord> createMedicalRecord(MedicalRecord record) async {
    try {
      final response = await _dio.post(
        '/medical/records',
        data: record.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return MedicalRecord.fromJson(response.data);
      } else {
        throw Exception('Failed to create medical record: ${response.data}');
      }
    } catch (e) {
      AppLogger.error('MedicalService | Error creating medical record: $e');
      rethrow;
    }
  }

  Future<MedicalRecord?> getTodayRecord(String childId) async {
    try {
      String today = DateTime.now().toIso8601String().split('T')[0];
      final response = await _dio.get(
        '/medical/records/today',
        queryParameters: {
          'childId': childId,
          'date': today,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null) {
          return MedicalRecord.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      // It's normal to have no record for today
      AppLogger.debug('MedicalService | No record for today for child $childId');
      return null;
    }
  }
}
