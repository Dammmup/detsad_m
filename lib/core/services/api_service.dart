import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';
import '../utils/logger.dart';

class ApiService {
  late final Dio _dio;
  final StorageService _storageService = StorageService();

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onRequest: (options, handler) async {
          try {
            AppLogger.debug(
                'ApiService | REQUEST [${options.method}] ${options.path}');
            await StorageService.ensureInitialized();
            final token = await _storageService.getToken();

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
              AppLogger.debug(
                  'ApiService | Token added to headers (prefix: ${token.substring(0, min(5, token.length))}...)');
            } else {
              AppLogger.warning(
                  'ApiService | No token found in storage for request to ${options.path}');
            }
          } catch (e) {
            AppLogger.error('ApiService | Error in onRequest: $e');
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          AppLogger.error(
              'ApiService | ERROR [${error.response?.statusCode}] ${error.requestOptions.path}: ${error.message}');

          if (error.response?.statusCode == 401) {
            AppLogger.warning(
                'ApiService | Unauthorized access (401). Keeping token for investigation.');
            // Мы больше не удаляем токен автоматически, чтобы избежать "смертельной петли"
            // при случайных ошибках сервера.
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Вспомогательный метод для логов
  int min(int a, int b) => a < b ? a : b;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> uploadFile(
    String path,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        ...?additionalData,
      });

      final response = await _dio.post(
        path,
        data: formData,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
