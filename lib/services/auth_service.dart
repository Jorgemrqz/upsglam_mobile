import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/profile.dart';

class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'AuthException(statusCode: $statusCode, message: $message)';
}

class AuthService {
  AuthService._internal({http.Client? client}) : _client = client ?? http.Client();

  static final AuthService instance = AuthService._internal();

  final http.Client _client;

  static const String _accessTokenKey = 'upsglam.accessToken';
  static const String _refreshTokenKey = 'upsglam.refreshToken';
  static const String _emailKey = 'upsglam.email';
  static const String _firebaseUidKey = 'upsglam.firebaseUid';
  static const String _profileKey = 'upsglam.profile';

  Future<String> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await ApiConfig.ensureInitialized();
    final Uri registerUri = ApiConfig.uriFor('/auth/register');
    try {
      final response = await _client
          .post(
            registerUri,
            headers: const {
              HttpHeaders.contentTypeHeader: 'application/json',
            },
            body: jsonEncode({
              'userName': name.trim(),
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _extractMessage(response.body) ?? 'Cuenta creada correctamente';
      }

      throw AuthException(
        _extractMessage(response.body) ?? 'No se pudo registrar (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on StateError catch (error) {
      throw AuthException(error.message);
    } on SocketException {
      throw const AuthException('No se pudo conectar con el API Gateway');
    } on TimeoutException {
      throw const AuthException('El API Gateway tardó demasiado en responder');
    }
  }

  Future<void> login({required String email, required String password}) async {
    await ApiConfig.ensureInitialized();
    final Uri loginUri = ApiConfig.uriFor('/auth/login');
    try {
      final response = await _client
          .post(
            loginUri,
            headers: const {
              HttpHeaders.contentTypeHeader: 'application/json',
            },
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        await _persistTokensFromBody(response.body);
        return;
      }

      throw AuthException(
        _extractMessage(response.body) ?? 'Error al autenticar (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on StateError catch (error) {
      throw AuthException(error.message);
    } on SocketException {
      throw const AuthException('No se pudo conectar con el API Gateway');
    } on TimeoutException {
      throw const AuthException('El API Gateway tardó demasiado en responder');
    }
  }

  Future<bool> hasValidSession() async {
    await ApiConfig.ensureInitialized();
    final token = await _readAccessToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    final Uri meUri = ApiConfig.uriFor('/auth/me');
    try {
      final response = await _client
          .get(
            meUri,
            headers: {
              HttpHeaders.authorizationHeader: 'Bearer $token',
            },
          )
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        return true;
      }

      if (response.statusCode == 401) {
        await logout();
        return false;
      }

      throw AuthException(
        _extractMessage(response.body) ?? 'No se pudo validar la sesión (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on StateError {
      return false;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_firebaseUidKey);
    await prefs.remove(_profileKey);
  }

  Future<String?> getStoredAccessToken() => _readAccessToken();

  Future<void> _persistTokens({required String accessToken, String? refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  Future<void> _persistTokensFromBody(String body) async {
    final Map<String, dynamic> payload = jsonDecode(body) as Map<String, dynamic>;
    final String? accessToken =
        (payload['accessToken'] as String?) ?? (payload['jwt'] as String?);
    final String? refreshToken = payload['refreshToken'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw const AuthException('El backend no retornó un token válido');
    }
    await _persistTokens(accessToken: accessToken, refreshToken: refreshToken);
    await _persistSessionMetadata(
      email: payload['email'] as String?,
      firebaseUid: (payload['uid'] as String?) ?? (payload['firebaseUid'] as String?),
      profileJson: payload['profile'] as Map<String, dynamic>?,
    );
  }

  Future<void> _persistSessionMetadata({
    String? email,
    String? firebaseUid,
    Map<String, dynamic>? profileJson,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (email != null && email.isNotEmpty) {
      await prefs.setString(_emailKey, email.trim());
    } else {
      await prefs.remove(_emailKey);
    }
    if (firebaseUid != null && firebaseUid.isNotEmpty) {
      await prefs.setString(_firebaseUidKey, firebaseUid);
    } else {
      await prefs.remove(_firebaseUidKey);
    }
    if (profileJson != null && profileJson.isNotEmpty) {
      await prefs.setString(_profileKey, jsonEncode(profileJson));
    } else {
      await prefs.remove(_profileKey);
    }
  }

  Future<String?> _readAccessToken() => _readString(_accessTokenKey);

  Future<String?> getStoredEmail() => _readString(_emailKey);

  Future<String?> getStoredFirebaseUid() => _readString(_firebaseUidKey);

  Future<ProfileModel?> getStoredProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return ProfileModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheProfile(ProfileModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<String?> _readString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  String? _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded['message'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
