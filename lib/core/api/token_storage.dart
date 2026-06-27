import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage() : _storage = const FlutterSecureStorage();
  final FlutterSecureStorage _storage;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey = 'current_user';

  // In-memory cache — always current for this session
  String? _accessToken;
  String? _refreshToken;

  Future<void> saveTokens({required String access, required String refresh}) async {
    _accessToken = access;
    _refreshToken = refresh;
    try {
      await Future.wait([
        _storage.write(key: _accessKey, value: access),
        _storage.write(key: _refreshKey, value: refresh),
      ]);
    } catch (_) {
      // Secure storage may fail on HTTP/web — in-memory cache is the fallback
    }
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    try {
      await _storage.write(key: _userKey, value: jsonEncode(user));
    } catch (_) {}
  }

  Future<String?> getAccessToken() async {
    if (_accessToken != null) return _accessToken;
    try {
      _accessToken = await _storage.read(key: _accessKey);
    } catch (_) {}
    return _accessToken;
  }

  Future<String?> getRefreshToken() async {
    if (_refreshToken != null) return _refreshToken;
    try {
      _refreshToken = await _storage.read(key: _refreshKey);
    } catch (_) {}
    return _refreshToken;
  }

  Future<Map<String, dynamic>?> getUser() async {
    try {
      final raw = await _storage.read(key: _userKey);
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Decodes the JWT payload without verifying the signature.
  /// Returns null if the token is missing, malformed, or expired.
  Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      // Pad base64url to a multiple of 4
      final rem = payload.length % 4;
      if (rem == 2) payload += '==';
      if (rem == 3) payload += '=';
      final decoded = utf8.decode(base64Url.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  bool isTokenExpired(String token) {
    final payload = decodePayload(token);
    if (payload == null) return true;
    final exp = payload['exp'];
    if (exp == null) return true;
    final expiry = DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
    return DateTime.now().isAfter(expiry);
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    try {
      await Future.wait([
        _storage.delete(key: _accessKey),
        _storage.delete(key: _refreshKey),
        _storage.delete(key: _userKey),
      ]);
    } catch (_) {}
  }
}
