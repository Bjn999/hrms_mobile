import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_endpoints.dart';
import '../error/exceptions.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';

class DioClient {
  late final Dio _dio;
  final SecureStorageService _storageService;

  DioClient(this._storageService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.defaultBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add Auth Interceptor
    _dio.interceptors.add(AuthInterceptor(_storageService));

    // Add Logging in Debug Mode
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }
  }

  Dio get dio => _dio;

  // Convenience Methods with Automatic Error Mapping
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return NetworkException(
        message: 'تعذر الاتصال بالخادم، يرجى التأكد من تشغيل السيرفر والاتصال بالشبكة',
      );
    }

    if (error.response != null) {
      final data = error.response?.data;
      String message = 'حدث خطأ في الخادم';

      if (data is Map<String, dynamic>) {
        if (data['message'] != null && data['message'].toString().isNotEmpty) {
          message = data['message'].toString();
        } else if (data['errors'] != null && data['errors'] is Map) {
          final errorsMap = data['errors'] as Map<String, dynamic>;
          final firstKey = errorsMap.keys.first;
          final errorValue = errorsMap[firstKey];
          if (errorValue is List && errorValue.isNotEmpty) {
            message = errorValue.first.toString();
          } else {
            message = errorValue.toString();
          }
        }
      }

      return ServerException(
        message: message,
        statusCode: error.response?.statusCode,
      );
    }

    return ServerException(
      message: error.message ?? 'حدث خطأ غير متوقع في الاتصال',
    );
  }
}
