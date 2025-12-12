import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:upsglam_mobile/config/api_config.dart';
import 'package:upsglam_mobile/models/profile.dart';
import 'package:upsglam_mobile/services/auth_service.dart';

class UserException implements Exception {
  const UserException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'UserException($message, $statusCode)';
}

class UserService {
  UserService._internal({http.Client? client})
    : _client = client ?? http.Client();

  static final UserService instance = UserService._internal();

  final http.Client _client;
  final AuthService _authService = AuthService.instance;

  Future<List<ProfileModel>> listUsers() async {
    await ApiConfig.ensureInitialized();
    final uri = ApiConfig.uriFor('/users');
    final token = await _authService.getStoredAccessToken();
    final headers = {
      HttpHeaders.acceptHeader: 'application/json',
      if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
    };

    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((json) => ProfileModel.fromJson(json)).toList();
        }
        return [];
      }
      throw UserException(
        'Error al listar usuarios (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is UserException) rethrow;
      throw const UserException(
        'No se pudo conectar con el servicio de usuarios',
      );
    }
  }

  Future<ProfileModel> getUser(String userId) async {
    await ApiConfig.ensureInitialized();
    final uri = ApiConfig.uriFor('/users/$userId');
    final token = await _authService.getStoredAccessToken();
    final headers = {
      HttpHeaders.acceptHeader: 'application/json',
      if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
    };

    final response = await _client
        .get(uri, headers: headers)
        .timeout(ApiConfig.defaultTimeout);

    if (response.statusCode == 200) {
      return ProfileModel.fromJson(jsonDecode(response.body));
    }
    throw UserException(
      'Usuario no encontrado',
      statusCode: response.statusCode,
    );
  }

  Future<void> followUser(String targetId) async {
    return _toggleFollow(targetId, true);
  }

  Future<void> unfollowUser(String targetId) async {
    return _toggleFollow(targetId, false);
  }

  Future<void> _toggleFollow(String targetId, bool follow) async {
    await ApiConfig.ensureInitialized();
    final uri = ApiConfig.uriFor('/users/$targetId/followers');
    final token = await _authService.getStoredAccessToken();
    final uid = await _authService.getStoredFirebaseUid();

    if (token == null || uid == null) {
      throw const UserException('Debes iniciar sesión');
    }

    final headers = {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer $token',
      'X-User-Uid': uid, // user-service requiere este header para la acción
    };

    final response =
        await (follow
                ? _client.post(uri, headers: headers)
                : _client.delete(uri, headers: headers))
            .timeout(ApiConfig.defaultTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    throw UserException(
      'No se pudo ${follow ? 'seguir' : 'dejar de seguir'} al usuario (${response.statusCode})',
      statusCode: response.statusCode,
    );
  }

  Future<Set<String>> getFollowingIds(String userId) async {
    await ApiConfig.ensureInitialized();
    final uri = ApiConfig.uriFor('/users/$userId/following');
    final token = await _authService.getStoredAccessToken();
    final headers = {
      if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
    };

    try {
      final response = await _client.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final list = decoded['following'] as List?;
        if (list != null) {
          return list.map((e) => e.toString()).toSet();
        }
      }
      return {};
    } catch (_) {
      return {};
    }
  }
}
