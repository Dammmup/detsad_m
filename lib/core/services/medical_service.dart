import '../constants/api_constants.dart';
import '../../models/medical_record.dart';
import '../utils/logger.dart';
import 'api_service.dart';

class MedicalService {
  final ApiService _apiService = ApiService();

  Future<List<MedicalRecord>> getMedicalRecords({
    required String childId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConstants.medicalRecords,
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
      final response = await _apiService.post(
        ApiConstants.medicalRecords,
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

  Future<List<MedicalRecord>> getTodayRecordsForDate(DateTime date) async {
    try {
      String dateStr = date.toIso8601String().split('T')[0];
      final response = await _apiService.get(
        ApiConstants.medicalRecords,
        queryParameters: {
          'date': dateStr,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => MedicalRecord.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.error('MedicalService | Error fetching records for date: $e');
      return [];
    }
  }

  Future<MedicalRecord> updateMedicalRecord(String id, MedicalRecord record) async {
    try {
      final response = await _apiService.put(
        '${ApiConstants.medicalRecords}/$id',
        data: record.toJson(),
      );

      if (response.statusCode == 200) {
        return MedicalRecord.fromJson(response.data);
      } else {
        throw Exception('Failed to update medical record: ${response.data}');
      }
    } catch (e) {
      AppLogger.error('MedicalService | Error updating medical record: $e');
      rethrow;
    }
  }

  Future<void> deleteMedicalRecord(String id) async {
    try {
      final response = await _apiService.delete('${ApiConstants.medicalRecords}/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete medical record');
      }
    } catch (e) {
      AppLogger.error('MedicalService | Error deleting medical record: $e');
      rethrow;
    }
  }

  Future<MedicalRecord?> getTodayRecord(String childId) async {
    try {
      String today = DateTime.now().toIso8601String().split('T')[0];
      final response = await _apiService.get(
        ApiConstants.medicalRecords,
        queryParameters: {
          'childId': childId,
          'date': today,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        if (data.isNotEmpty) {
          return MedicalRecord.fromJson(data.first);
        }
      }
      return null;
    } catch (e) {
      AppLogger.debug('MedicalService | No record for today for child $childId: $e');
      return null;
    }
  }
}
