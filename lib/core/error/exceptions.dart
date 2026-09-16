class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException: $message (code: $statusCode)';
}

class CacheException implements Exception {
  final String message;
  CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException({this.message = 'لا يوجد اتصال بالإنترنت'});

  @override
  String toString() => 'NetworkException: $message';
}

class BiometricException implements Exception {
  final String message;
  BiometricException({required this.message});

  @override
  String toString() => 'BiometricException: $message';
}
