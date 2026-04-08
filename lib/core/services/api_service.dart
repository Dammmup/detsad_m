import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import 'storage_service.dart';
import '../utils/logger.dart';

class ApiService {
  late final Dio _dio;
  final StorageService _storageService = StorageService();

  /// Глобальный ключ навигатора для редиректа при 401
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

            final token = await _storageService.getToken();

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            } else {
              AppLogger.error(
                  'ApiService | NO TOKEN FOUND for request to ${options.path}');
            }
          } catch (e, stackTrace) {
            AppLogger.error('ApiService | Error in onRequest: $e');
            AppLogger.error('ApiService | StackTrace: $stackTrace');
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final errorMessage = _handleDioError(error);
          AppLogger.error(
              'ApiService | ERROR [${error.response?.statusCode}] ${error.requestOptions.path}: $errorMessage');

          if (error.response?.statusCode == 401) {
            AppLogger.warning('ApiService | Unauthorized (401). Auto-logout.');
            await _storageService.clearAll();
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              'login', (route) => false,
            );
          }
          
          // Пробрасываем ошибку с понятным сообщением
          return handler.next(error.copyWith(message: errorMessage));
        },
      ),
    );
  }

  String _handleDioError(DioException error) {
    final responseData = error.response?.data;
    if (responseData != null && 
        responseData is Map && 
        responseData['error'] != null) {
      return responseData['error'].toString();
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Превышено время ожидания подключения. Проверьте интернет.';
      case DioExceptionType.sendTimeout:
        return 'Ошибка отправки данных. Попробуйте снова.';
      case DioExceptionType.receiveTimeout:
        return 'Сервер слишком долго отвечает. Попробуйте позже.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 400) return 'Некорректный запрос к серверу.';
        if (statusCode == 401) return 'Ошибка авторизации. Войдите заново.';
        if (statusCode == 403) return 'Доступ запрещен.';
        if (statusCode == 404) return 'Ресурс не найден.';
        if (statusCode == 429) return 'Слишком много запросов. Подождите немного.';
        if (statusCode != null && statusCode >= 500) {
          return 'Ошибка на стороне сервера. Мы скоро это исправим.';
        }
        return 'Произошла ошибка сервера: $statusCode';
      case DioExceptionType.cancel:
        return 'Запрос был отменен.';
      case DioExceptionType.connectionError:
        return 'Отсутствует интернет-соединение.';
      default:
        return 'Произошла непредвиденная ошибка. Попробуйте позже.';
    }
  }

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
