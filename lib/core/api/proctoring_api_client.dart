import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ProctoringApiClient {
  ProctoringApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://matchiq-ia.coderhivex.com',
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
    } catch (e) {
      debugPrint('[ProctoringAPI] POST $path failed: $e');
      return null;
    }
  }
}
