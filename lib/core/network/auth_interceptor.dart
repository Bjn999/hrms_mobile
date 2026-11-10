import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;

  AuthInterceptor(this._storageService);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. Base URL strictly from .env
    if (!options.path.startsWith('http')) {
      options.baseUrl = ApiEndpoints.defaultBaseUrl;
    }

    // 2. Add Standard Headers
    options.headers['Accept'] = 'application/json';
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept-Language'] = 'ar';

    // 3. Inject Bearer Token if available
    final token = await _storageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final data = err.response?.data;
    final isSubscriptionSuspended = statusCode == 403 &&
        data is Map &&
        data['error_code'] == 'SUBSCRIPTION_SUSPENDED';

    if (statusCode == 401 || isSubscriptionSuspended) {
      // Session expired, token invalid, or company subscription suspended
      _storageService.clearAllSession();
    }
    return handler.next(err);
  }
}
