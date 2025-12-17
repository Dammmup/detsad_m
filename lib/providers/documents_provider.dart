import 'package:flutter/material.dart';
import '../core/services/documents_service.dart';

class DocumentsProvider with ChangeNotifier {
  final DocumentsService _documentsService = DocumentsService();

  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDocuments() async {
    _isLoading = true;
    notifyListeners();

    try {
      _documents = await _documentsService.getAllDocuments();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic>? getDocumentById(String id) {
    return _documents.firstWhere((doc) => doc['_id'] == id || doc['id'] == id,
        orElse: () => _documents.first);
  }

  Future<void> uploadDocument(String filePath,
      {Map<String, dynamic>? additionalData}) async {
    try {
      final newDocument = await _documentsService.uploadDocument(filePath,
          additionalData: additionalData);
      if (newDocument != null) {
        _documents.add(newDocument);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> downloadDocument(String documentId, String savePath) async {
    try {
      return await _documentsService.downloadDocument(documentId, savePath);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteDocument(String id) async {
    try {
      final success = await _documentsService.deleteDocument(id);
      if (success) {
        _documents.removeWhere((doc) => doc['_id'] == id || doc['id'] == id);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
