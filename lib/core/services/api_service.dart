import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';

class ApiService {
  late final Dio _dio;
  final StorageService _storageService = StorageService();

  ApiService() {
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

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token to headers
          final token = await _storageService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('📤 Запрос: ${options.method} ${options.uri}');
          if (options.data != null) {
            print('📥 Тело запроса: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ Ответ: ${response.statusCode} для ${response.requestOptions.path}');
          print('📤 Тело ответа: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          print('❌ Ошибка: ${error.message}');
          print('📝 Детали ошибки: ${error.response?.data ?? error.message}');
          // Handle 401 Unauthorized
          if (error.response?.statusCode == 401) {
            // Clear token and redirect to login
            await _storageService.clearToken();
            // You can add navigation logic here or emit an event
          }
          return handler.next(error);
        },
      ),
    );
  }

  // GET request
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
      print('❌ Ошибка GET запроса: $e');
      rethrow;
    }
 }

  // POST request
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
      print('❌ Ошибка POST запроса: $e');
      rethrow;
    }
  }

 // PUT request
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
      print('❌ Ошибка PUT запроса: $e');
      rethrow;
    }
  }

 // PATCH request
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
      print('❌ Ошибка PATCH запроса: $e');
      rethrow;
    }
  }

  // DELETE request
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
      print('❌ Ошибка DELETE запроса: $e');
      rethrow;
    }
 }

  // Upload file
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
      print('❌ Ошибка загрузки файла: $e');
      rethrow;
    }
  }
}