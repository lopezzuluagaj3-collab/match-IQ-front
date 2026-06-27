class ServerException implements Exception {
  const ServerException({required this.message, this.statusCode = 500});
  final String message;
  final int statusCode;
}

class NetworkException implements Exception {
  const NetworkException({this.message = 'No internet connection'});
  final String message;
}

class CacheException implements Exception {
  const CacheException({required this.message});
  final String message;
}

class AuthException implements Exception {
  const AuthException({required this.message, this.statusCode = 401});
  final String message;
  final int statusCode;
}
