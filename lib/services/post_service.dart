import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/post.dart';
import 'auth_service.dart';

class PostException implements Exception {
  const PostException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'PostException(statusCode: $statusCode, message: $message)';
}

class PostService {
  PostService._({http.Client? client}) : _client = client ?? http.Client();

  static final PostService instance = PostService._();

  final http.Client _client;
  final AuthService _authService = AuthService.instance;

  Future<List<PostModel>> fetchFeed() async {
    await ApiConfig.ensureInitialized();
    final uri = ApiConfig.uriFor('/posts');
    final headers = await _authorizedHeaders(optional: true);
    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(ApiConfig.defaultTimeout);
      if (response.statusCode == 200) {
        return _parsePosts(response.body);
      }
      throw PostException(
        _extractMessage(response.body) ??
            'No se pudo cargar el feed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw const PostException('No se pudo conectar con el API Gateway');
    } on TimeoutException {
      throw const PostException('El API Gateway tardó demasiado en responder');
    }
  }

  Future<List<PostModel>> fetchPostsByUser(String userId) async {
    await ApiConfig.ensureInitialized();
    final uri = ApiConfig.uriFor('/posts/user/$userId');
    final headers = await _authorizedHeaders(optional: true);
    try {
      print('DEBUG: Calling GET $uri');
      final response = await _client
          .get(uri, headers: headers)
          .timeout(ApiConfig.defaultTimeout);

      print('DEBUG: Response ${response.statusCode}');
      print('DEBUG: Body ${response.body}');

      developer.log(
        'GET /posts/user/$userId => ${response.statusCode}',
        name: 'PostService',
        error: response.body.length > 500
            ? response.body.substring(0, 500)
            : response.body,
      );

      if (response.statusCode == 200) {
        return _parsePosts(response.body);
      }
      throw PostException(
        _extractMessage(response.body) ??
            'No se pudo cargar los posts del usuario (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw const PostException('No se pudo conectar con el API Gateway');
    } on TimeoutException {
      throw const PostException('El API Gateway tardó demasiado en responder');
    }
  }

  Future<PostModel> createPost({
    required String imageUrl,
    String? content,
  }) async {
    await ApiConfig.ensureInitialized();
    final token = await _authService.getStoredAccessToken();
    if (token == null || token.isEmpty) {
      throw const PostException('Debes iniciar sesión para publicar contenido');
    }

    final payload = <String, dynamic>{'imageUrl': imageUrl.trim()};
    final trimmedContent = content?.trim();
    if (trimmedContent != null && trimmedContent.isNotEmpty) {
      payload['content'] = trimmedContent;
    }

    final uri = ApiConfig.uriFor('/posts');
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json',
              HttpHeaders.authorizationHeader: 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(ApiConfig.defaultTimeout);

      developer.log(
        'POST /posts => ${response.statusCode}',
        name: 'PostService',
        error: response.body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final rawBody = response.body.trim();
        return _parsePostFromBody(
          rawBody,
          emptyMessage: 'El backend no devolvió datos del post creado',
        );
      }

      throw PostException(
        _extractMessage(response.body) ??
            'No se pudo crear el post (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw const PostException('No se pudo conectar con el API Gateway');
    } on TimeoutException {
      throw const PostException('El API Gateway tardó demasiado en responder');
    }
  }

  Future<Map<String, String>> _authorizedHeaders({
    bool optional = false,
  }) async {
    final base = <String, String>{HttpHeaders.acceptHeader: 'application/json'};
    final token = await _authService.getStoredAccessToken();
    if (token == null || token.isEmpty) {
      if (optional) return base;
      throw const PostException('Sin credenciales válidas');
    }
    return {...base, HttpHeaders.authorizationHeader: 'Bearer $token'};
  }

  List<PostModel> _parsePosts(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is List) {
        return PostModel.listFrom(decoded);
      }
      if (decoded is Map<String, dynamic>) {
        if (decoded['posts'] is List) {
          return PostModel.listFrom(decoded['posts']);
        }
        if (decoded['data'] is List ||
            decoded['data'] is Map<String, dynamic>) {
          return PostModel.listFrom(decoded['data']);
        }
        return [PostModel.fromJson(decoded)];
      }
      return const [];
    } catch (_) {
      return const [];
    }
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

  Future<PostModel> likePost(String postId) => _mutateLike(postId, like: true);

  Future<PostModel> unlikePost(String postId) =>
      _mutateLike(postId, like: false);

  Future<PostModel> fetchPostById(String postId) async {
    await ApiConfig.ensureInitialized();
    final uri = ApiConfig.uriFor('/posts/$postId');
    final headers = await _authorizedHeaders(optional: true);
    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(ApiConfig.defaultTimeout);
      if (response.statusCode == 200) {
        return _parsePostFromBody(
          response.body.trim(),
          emptyMessage: 'El backend no devolvió datos del post',
        );
      }
      throw PostException(
        _extractMessage(response.body) ??
            'No se pudo obtener el post (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw const PostException('No se pudo conectar con el API Gateway');
    } on TimeoutException {
      throw const PostException('El API Gateway tardó demasiado en responder');
    }
  }

  Future<PostModel> addComment(String postId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const PostException('Escribe un comentario antes de enviarlo');
    }
    await ApiConfig.ensureInitialized();
    final headers = await _authorizedHeaders();
    final uri = ApiConfig.uriFor('/posts/$postId/comments');
    final payloadHeaders = {
      ...headers,
      HttpHeaders.contentTypeHeader: 'application/json',
    };
    try {
      final response = await _client
          .post(
            uri,
            headers: payloadHeaders,
            body: jsonEncode({'text': trimmed}),
          )
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        return _parsePostFromBody(
          response.body.trim(),
          emptyMessage: 'El backend no devolvió el post actualizado',
        );
      }

      throw PostException(
        _extractMessage(response.body) ??
            'No se pudo enviar el comentario (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw const PostException('No se pudo conectar con el API Gateway');
    } on TimeoutException {
      throw const PostException('El API Gateway tardó demasiado en responder');
    }
  }

  Future<PostModel> _mutateLike(String postId, {required bool like}) async {
    await ApiConfig.ensureInitialized();
    final headers = await _authorizedHeaders();
    final uri = ApiConfig.uriFor('/posts/$postId/likes');
    try {
      final response =
          await (like
                  ? _client.post(uri, headers: headers)
                  : _client.delete(uri, headers: headers))
              .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        return _parsePostFromBody(
          response.body.trim(),
          emptyMessage: 'El backend no devolvió datos del post actualizado',
        );
      }

      throw PostException(
        _extractMessage(response.body) ??
            'No se pudo ${like ? 'dar like' : 'quitar el like'} (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw const PostException('No se pudo conectar con el API Gateway');
    } on TimeoutException {
      throw const PostException('El API Gateway tardó demasiado en responder');
    }
  }

  Future<PostModel> updatePostContent(String postId, String? content) async {
    await ApiConfig.ensureInitialized();
    final headers = await _authorizedHeaders();
    final uri = ApiConfig.uriFor('/posts/$postId');
    final payloadHeaders = {
      ...headers,
      HttpHeaders.contentTypeHeader: 'application/json',
    };
    final body = <String, dynamic>{'content': content?.trim() ?? ''};
    try {
      final response = await _client
          .put(uri, headers: payloadHeaders, body: jsonEncode(body))
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200) {
        return _parsePostFromBody(
          response.body.trim(),
          emptyMessage: 'El backend no devolvió el post editado',
        );
      }

      throw PostException(
        _extractMessage(response.body) ??
            'No se pudo editar el post (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw const PostException('No se pudo conectar con el API Gateway');
    } on TimeoutException {
      throw const PostException('El API Gateway tardó demasiado en responder');
    }
  }

  Future<void> deletePost(String postId) async {
    await ApiConfig.ensureInitialized();
    final headers = await _authorizedHeaders();
    final uri = ApiConfig.uriFor('/posts/$postId');
    try {
      final response = await _client
          .delete(uri, headers: headers)
          .timeout(ApiConfig.defaultTimeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }

      throw PostException(
        _extractMessage(response.body) ??
            'No se pudo eliminar el post (${response.statusCode})',
        statusCode: response.statusCode,
      );
    } on SocketException {
      throw const PostException('No se pudo conectar con el API Gateway');
    } on TimeoutException {
      throw const PostException('El API Gateway tardó demasiado en responder');
    }
  }

  PostModel _parsePostFromBody(String rawBody, {required String emptyMessage}) {
    if (rawBody.isEmpty) {
      throw PostException(emptyMessage);
    }
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        if (decoded['data'] is Map<String, dynamic>) {
          return PostModel.fromJson(decoded['data'] as Map<String, dynamic>);
        }
        return PostModel.fromJson(decoded);
      }
      if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.first;
        if (first is Map<String, dynamic>) {
          return PostModel.fromJson(first);
        }
      }
    } on FormatException {
      throw PostException('Respuesta inesperada del backend: $rawBody');
    }
    throw const PostException('El backend no devolvió un JSON válido de post');
  }
}
