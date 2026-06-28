import 'dart:io';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../errors/failures.dart';
import 'api_constants.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient(this._tokenStorage) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(_AuthInterceptor(_tokenStorage, _dio));
  }

  final TokenStorage _tokenStorage;
  late final Dio _dio;

  Future<Either<Failure, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
    bool skipAuth = false,
  }) async {
    try {
      final res = await _dio.get(
        path,
        queryParameters: queryParams,
        options: Options(extra: {'skipAuth': skipAuth}),
      );
      return _parseResponse(res);
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }

  Future<Either<Failure, dynamic>> post(
    String path, {
    dynamic body,
    bool skipAuth = false,
  }) async {
    try {
      final res = await _dio.post(
        path,
        data: body,
        options: Options(extra: {'skipAuth': skipAuth}),
      );
      return _parseResponse(res);
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }

  Future<Either<Failure, dynamic>> put(
    String path, {
    dynamic body,
  }) async {
    try {
      final res = await _dio.put(path, data: body);
      return _parseResponse(res);
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }

  Future<Either<Failure, dynamic>> patch(
    String path, {
    dynamic body,
  }) async {
    try {
      final res = await _dio.patch(path, data: body);
      return _parseResponse(res);
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Downloads raw bytes — used for binary responses like Excel files.
  Future<Either<Failure, Uint8List>> getBytes(String path) async {
    try {
      final res = await _dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      return Right(Uint8List.fromList(res.data ?? []));
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }

  Future<Either<Failure, dynamic>> delete(String path) async {
    try {
      final res = await _dio.delete(path);
      return _parseResponse(res);
    } on DioException catch (e) {
      return Left(_handleError(e));
    }
  }

  // Checks the "success" field as required by the API contract.
  // If success == false, returns Left with the message even on HTTP 200.
  Either<Failure, dynamic> _parseResponse(Response res) {
    final body = res.data;
    if (body is! Map) return Right(body);

    final success = body['success'];
    if (success == false) {
      final message = body['message'] as String? ?? 'Error desconocido';
      return Left(ServerFailure(message: message, statusCode: res.statusCode ?? 400));
    }
    return Right(body['data']);
  }

  Failure _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.error is SocketException) {
      return const NetworkFailure();
    }

    final statusCode = e.response?.statusCode ?? 500;
    final message = _extractMessage(e, statusCode);

    return switch (statusCode) {
      401 => AuthFailure(message: message, statusCode: statusCode),
      _ => ServerFailure(message: message, statusCode: statusCode),
    };
  }

  String _extractMessage(DioException e, int statusCode) {
    final data = e.response?.data;

    if (data is Map) {
      // Custom API format: { "success": false, "message": "..." }
      final apiMessage = data['message'];
      if (apiMessage is String && apiMessage.isNotEmpty) return apiMessage;

      // ASP.NET validation format: { "errors": { "Field": ["msg1", "msg2"] } }
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        return errors.values
            .expand((v) => v is List ? v.cast<String>() : [v.toString()])
            .join('\n');
      }

      // ASP.NET title fallback
      final title = data['title'];
      if (title is String && title.isNotEmpty) return title;
    }

    // Fallback messages by status code
    return switch (statusCode) {
      400 => 'Datos inválidos. Revisa los campos del formulario.',
      401 => 'Tu sesión expiró. Inicia sesión nuevamente.',
      403 => 'No tienes permiso para realizar esta acción.',
      404 => 'El recurso solicitado no fue encontrado.',
      409 => 'Ya existe un registro con esos datos.',
      429 => 'Demasiadas solicitudes. Espera al menos 60 segundos.',
      500 => 'Error interno del servidor. Intenta más tarde.',
      _ => e.message ?? 'Error inesperado. Intenta de nuevo.',
    };
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._storage, this._dio);
  final TokenStorage _storage;
  final Dio _dio;
  bool _isRefreshing = false;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] == true) return handler.next(options);

    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 || _isRefreshing) {
      return handler.next(err);
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        _isRefreshing = false;
        return handler.next(err);
      }

      final refreshRes = await _dio.post(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );

      final data = refreshRes.data['data'] as Map<String, dynamic>;
      await _storage.saveTokens(
        access: data['accessToken'] as String,
        refresh: data['refreshToken'] as String,
      );

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer ${data['accessToken']}';
      final retryRes = await _dio.fetch(retryOptions);
      _isRefreshing = false;
      handler.resolve(retryRes);
    } catch (_) {
      _isRefreshing = false;
      await _storage.clear();
      handler.next(err);
    }
  }
}
