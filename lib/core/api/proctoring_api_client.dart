import 'package:dio/dio.dart';

class ProctoringApiClient {
  ProctoringApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:5000',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  late final Dio _dio;

  Future<Map<String, dynamic>?> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(path, data: body);
      return res.data;
    } catch (_) {
      return null;
    }
  }
}
