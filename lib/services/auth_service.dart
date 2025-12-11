import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/processed_image_result.dart';
import '../models/profile.dart';

class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'AuthException(statusCode: $statusCode, message: $message)';
}

class AuthService {
  AuthService._internal({http.Client? client})
    : _client = client ?? http.Client();

  static final AuthService instance = AuthService._internal();

  final http.Client _client;
  final StreamController<ProfileModel> _profileStreamController =
      StreamController<ProfileModel>.broadcast();

  Stream<ProfileModel> get profileUpdates => _profileStreamController.stream;

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
            headers: const {HttpHeaders.contentTypeHeader: 'application/json'},
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
        _extractMessage(response.body) ??
            'No se pudo registrar (${response.statusCode})',
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
            headers: const {HttpHeaders.contentTypeHeader: 'application/json'},
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        await _persistTokensFromBody(response.body);
        return;
      }

      throw AuthException(
        _extractMessage(response.body) ??
            'Error al autenticar (${response.statusCode})',
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
            headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
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
        _extractMessage(response.body) ??
            'No se pudo validar la sesión (${response.statusCode})',
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

  Future<void> _persistTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  Future<void> _persistTokensFromBody(String body) async {
    final Map<String, dynamic> payload =
        jsonDecode(body) as Map<String, dynamic>;
    final String? accessToken =
        (payload['accessToken'] as String?) ?? (payload['jwt'] as String?);
    final String? refreshToken = payload['refreshToken'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw const AuthException('El backend no retornó un token válido');
    }
    await _persistTokens(accessToken: accessToken, refreshToken: refreshToken);
    await _persistSessionMetadata(
      email: payload['email'] as String?,
      firebaseUid:
          (payload['uid'] as String?) ?? (payload['firebaseUid'] as String?),
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
    _profileStreamController.add(profile);
  }

  Future<ProfileModel> uploadAvatar({
    required List<int> bytes,
    String fileName = 'avatar.png',
  }) async {
    await ApiConfig.ensureInitialized();
    final uid = await getStoredFirebaseUid();
    if (uid == null || uid.isEmpty) {
      throw const AuthException(
        'No se encontró el identificador del usuario para subir el avatar',
      );
    }

    // 1. Subir imagen al image-service
    final Uri uploadUri = ApiConfig.uriFor('/images/avatar');
    final request = http.MultipartRequest('POST', uploadUri)
      ..headers['X-User-Uid'] = uid;

    final token = await _readAccessToken();
    if (token != null && token.isNotEmpty) {
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    String uploadedUrl;
    try {
      final streamedResponse = await request.send().timeout(
        ApiConfig.defaultTimeout,
      );
      final body = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        // Parsear AvatarUploadResponse (image-service)
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic> &&
            decoded.containsKey('avatarUrl')) {
          uploadedUrl = decoded['avatarUrl'] as String;
        } else {
          throw const AuthException(
            'La respuesta del servidor de imágenes no contiene la URL',
          );
        }
      } else {
        throw AuthException(
          _extractMessage(body) ??
              'No se pudo subir el avatar (${streamedResponse.statusCode})',
          statusCode: streamedResponse.statusCode,
        );
      }
    } on SocketException {
      throw const AuthException(
        'No se pudo conectar con el API Gateway (Image Service)',
      );
    } on TimeoutException {
      throw const AuthException(
        'El API Gateway tardó demasiado en responder (Image Service)',
      );
    }

    // 2. Vincular avatar al usuario (user-service)
    return _addAvatarToUser(uid, uploadedUrl);
  }

  Future<ProfileModel> _addAvatarToUser(String userId, String avatarUrl) async {
    await ApiConfig.ensureInitialized();
    final token = await _readAccessToken();
    final Uri linkUri = ApiConfig.uriFor('/users/$userId/avatars');

    try {
      final response = await _client
          .post(
            linkUri,
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json',
              if (token != null)
                HttpHeaders.authorizationHeader: 'Bearer $token',
            },
            body: jsonEncode({'avatarUrl': avatarUrl}),
          )
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        final profile = _parseProfileFromBody(response.body);
        if (profile != null) {
          await cacheProfile(profile);
          return profile;
        }
        throw const AuthException(
          'El backend no retornó el perfil actualizado',
        );
      }

      throw AuthException(
        _extractMessage(response.body) ??
            'No se pudo actualizar el avatar del usuario (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw const AuthException(
        'No se pudo conectar con el API Gateway (User Service)',
      );
    } on TimeoutException {
      throw const AuthException(
        'El API Gateway tardó demasiado en responder (User Service)',
      );
    }
  }

  Future<ProcessedImageResult> processImage({
    required List<int> bytes,
    required String mask,
    required String filter,
    String fileName = 'image.png',
  }) async {
    await ApiConfig.ensureInitialized();
    final token = await _readAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException(
        'Tu sesión expiró, vuelve a iniciar sesión para procesar imágenes',
      );
    }

    final Uri uploadUri = ApiConfig.uriFor('/images/upload');
    final request = http.MultipartRequest('POST', uploadUri)
      ..headers[HttpHeaders.authorizationHeader] = 'Bearer $token'
      ..fields['mask'] = mask.trim()
      ..fields['filter'] = filter.trim();

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    try {
      final streamedResponse = await request.send().timeout(
        ApiConfig.defaultTimeout,
      );
      final body = await streamedResponse.stream.bytesToString();
      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          final result = ProcessedImageResult.fromJson(decoded);
          if (result.hasProcessedUrl || result.originalUrl != null) {
            return result;
          }
        }
        throw const AuthException(
          'El backend no retornó las URLs de la imagen procesada',
        );
      }

      throw AuthException(
        _extractMessage(body) ??
            'No se pudo procesar la imagen (${streamedResponse.statusCode})',
        statusCode: streamedResponse.statusCode,
      );
    } on SocketException {
      throw const AuthException('No se pudo conectar con el API Gateway');
    } on TimeoutException {
      throw const AuthException('El API Gateway tardó demasiado en responder');
    }
  }

  Future<ProfileModel> updateProfile({
    required String username,
    required String name,
    String? bio,
    String? avatarUrl,
  }) async {
    await ApiConfig.ensureInitialized();
    final token = await _readAccessToken();
    if (token == null || token.isEmpty) {
      throw const AuthException(
        'Tu sesión expiró, vuelve a iniciar sesión para editar el perfil',
      );
    }

    final profileData = await getStoredProfile();
    final userId = profileData?.id;

    // Si no tenemos ID local, intentamos usar el UID de Firebase o fallamos?
    // User Service usa su propio ID (que suele ser el UID de Firebase en este diseño).
    // Asumiremos que podemos usar el id del perfil guardado o el firebase uid.
    final targetId = userId ?? await getStoredFirebaseUid();

    if (targetId == null) {
      throw const AuthException(
        'No se pudo identificar al usuario para actualizar',
      );
    }

    final payload = <String, dynamic>{
      'username': username.trim(),
      'name': name.trim(),
    };

    final trimmedBio = bio?.trim();
    if (trimmedBio != null) {
      payload['bio'] = trimmedBio;
    }
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      payload['avatarUrl'] = avatarUrl.trim();
    }

    // UPDATE: PUT /users/{id}
    final Uri updateUri = ApiConfig.uriFor('/users/$targetId');
    try {
      final response = await _client
          .put(
            updateUri,
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json',
              HttpHeaders.authorizationHeader: 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // user-service devuelve el objeto User directo (no envuelto en "profile" key a veces).
        // _parseProfileFromBody intenta varias estructuras.
        final profile = _parseProfileFromBody(response.body);
        if (profile == null) {
          // Fallback simple si es directo User json
          try {
            final directUser = ProfileModel.fromJson(jsonDecode(response.body));
            await cacheProfile(directUser);
            return directUser;
          } catch (_) {
            throw const AuthException(
              'El backend no devolvió un perfil legible',
            );
          }
        }
        await cacheProfile(profile);
        return profile;
      }

      throw AuthException(
        _extractMessage(response.body) ??
            'No se pudo actualizar el perfil (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw const AuthException('No se pudo conectar con el API Gateway');
    } on TimeoutException {
      throw const AuthException('El API Gateway tardó demasiado en responder');
    }
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

  ProfileModel? _parseProfileFromBody(String body) {
    try {
      final dynamic decoded = jsonDecode(body);
      return _profileFromDecoded(decoded);
    } catch (_) {
      return null;
    }
  }

  ProfileModel? _profileFromDecoded(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final dynamic profilePayload = decoded['profile'] ?? decoded['data'];
      if (profilePayload is Map<String, dynamic>) {
        if (profilePayload.containsKey('profile')) {
          return ProfileModel.fromJson(
            profilePayload['profile'] as Map<String, dynamic>,
          );
        }
        if (_looksLikeProfile(profilePayload)) {
          return ProfileModel.fromJson(profilePayload);
        }
      }
      if (_looksLikeProfile(decoded)) {
        return ProfileModel.fromJson(decoded);
      }
    }
    return null;
  }

  bool _looksLikeProfile(Map<String, dynamic> data) {
    return data.containsKey('id') &&
        data.containsKey('name') &&
        data.containsKey('username');
  }
}
