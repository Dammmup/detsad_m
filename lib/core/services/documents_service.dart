import '../constants/api_constants.dart';
import 'api_service.dart';
import 'dart:io';

class DocumentsService {
  final ApiService _apiService = ApiService();

  // Get all documents
  Future<List<Map<String, dynamic>>> getAllDocuments() async {
    try {
      final response = await _apiService.get(ApiConstants.children);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        // Return children data as documents since in this app children data represents documents
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } on SocketException {
      throw Exception('Нет подключения к интернету');
    } catch (e) {
      throw Exception('Ошибка получения данных: $e');
    }
  }

  // Get document by ID
  Future<Map<String, dynamic>?> getDocumentById(String id) async {
    try {
      final response = await _apiService.get('${ApiConstants.children}/$id');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Upload document
  Future<Map<String, dynamic>?> uploadDocument(String filePath,
      {Map<String, dynamic>? additionalData}) async {
    try {
      final response = await _apiService.uploadFile(
        ApiConstants.children,
        filePath,
        additionalData: additionalData,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Download document
  Future<bool> downloadDocument(String documentId, String savePath) async {
    try {
      final response =
          await _apiService.get('${ApiConstants.children}/$documentId/download');
      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.data);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Delete document
  Future<bool> deleteDocument(String id) async {
    try {
      final response =
          await _apiService.delete('${ApiConstants.children}/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }
}