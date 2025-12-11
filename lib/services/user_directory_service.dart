import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/profile.dart';
import 'auth_service.dart';

class UserDirectoryException implements Exception {
  const UserDirectoryException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'UserDirectoryException(statusCode: $statusCode, message: $message)';
}

class UserDirectoryService {
  UserDirectoryService._({http.Client? client}) : _client = client ?? http.Client();

  static final UserDirectoryService instance = UserDirectoryService._();

  final http.Client _client;
  final AuthService _authService = AuthService.instance;
  final Map<String, ProfileModel?> _cache = <String, ProfileModel?>{};

  Future<ProfileModel?> getProfile(String userId, {bool forceRefresh = false}) async {
    if (userId.isEmpty) return null;
    if (!forceRefresh && _cache.containsKey(userId)) {
      return _cache[userId];
    }

    await ApiConfig.ensureInitialized();
    final token = await _authService.getStoredAccessToken();
    final uri = ApiConfig.uriFor('/users/$userId');
    final headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
      if (token != null && token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
    };

    try {
      final response = await _client.get(uri, headers: headers).timeout(ApiConfig.defaultTimeout);
      if (response.statusCode == 200) {
        final profile = _parseProfile(response.body);
        _cache[userId] = profile;
        return profile;
      }
      if (response.statusCode == 404) {
        _cache[userId] = null;
        return null;
      }
      throw UserDirectoryException(
        _extractMessage(response.body) ?? 'No se pudo obtener el perfil (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw const UserDirectoryException('No se pudo conectar con el API Gateway');
    } on TimeoutException {
      throw const UserDirectoryException('El API Gateway tardó demasiado en responder');
    }
  }

  ProfileModel? _parseProfile(String body) {
    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return ProfileModel.fromJson(decoded);
    }
    return null;
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
