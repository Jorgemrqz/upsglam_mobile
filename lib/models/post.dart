import 'post_comment.dart';

class PostModel {
  const PostModel({
    required this.id,
    required this.imageUrl,
    required this.authorName,
    this.content,
    this.authorUsername,
    this.authorAvatar,
    this.likes = 0,
    this.comments = 0,
    this.filter,
    this.mask,
    this.createdAt,
    this.userId,
    this.commentItems = const <PostCommentModel>[],
    this.likedByUserIds = const <String>[],
  });

  final String id;
  final String imageUrl;
  final String authorName;
  final String? content;
  final String? authorUsername;
  final String? authorAvatar;
  final int likes;
  final int comments;
  final String? filter;
  final String? mask;
  final DateTime? createdAt;
  final String? userId;
  final List<PostCommentModel> commentItems;
  final List<String> likedByUserIds;

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final likeUsers = _parseStringList(json['likes']);
    final comments = PostCommentModel.listFrom(json['comments']);

    // Procesar contenido para extraer metadata oculta
    String? rawContent = (json['content'] as String?)?.trim();
    String? matchedFilter = (json['filter'] as String?)?.trim();
    String? matchedMask = (json['mask'] as String?)?.trim();

    if (rawContent != null) {
      final metaRegex = RegExp(r'<METADATA:v1\|filter=([^|]*)\|mask=([^|>]*)>');
      final match = metaRegex.firstMatch(rawContent);
      if (match != null) {
        matchedFilter = match.group(1);
        matchedMask = match.group(2);
        // Limpiamos el contenido visible
        rawContent = rawContent.replaceAll(match.group(0)!, '').trim();
      }
    }

    return PostModel(
      id: (json['id'] as String?) ?? (json['postId'] as String?) ?? '',
      imageUrl: () {
        final rawUrl = (json['imageUrl'] as String?)?.trim();
        if (rawUrl != null && rawUrl.isNotEmpty) {
          return rawUrl;
        }
        return 'https://via.placeholder.com/600x400?text=UPSGlam';
      }(),
      content: rawContent?.isEmpty == true ? null : rawContent,
      authorName: (json['authorName'] as String?)?.trim() ?? 'Usuario UPSGlam',
      authorUsername: (json['authorUsername'] as String?)?.trim(),
      authorAvatar: _resolveAuthorAvatar(json),
      likes:
          _extractCount(json['likeCount']) ??
          (likeUsers != null
              ? likeUsers.length
              : _extractCount(json['likes'])) ??
          0,
      comments: comments.isNotEmpty
          ? comments.length
          : _extractCount(json['comments']) ??
                _extractCount(json['commentCount']) ??
                0,
      filter: matchedFilter,
      mask: matchedMask,
      createdAt: _parseDate(json['createdAt']),
      userId: (json['userId'] as String?)?.trim(),
      commentItems: List.unmodifiable(comments),
      likedByUserIds: likeUsers ?? const <String>[],
    );
  }

  bool isLikedBy(String? userId) {
    if (userId == null || userId.isEmpty) return false;
    return likedByUserIds.contains(userId);
  }

  PostModel copyWith({
    String? id,
    String? imageUrl,
    String? authorName,
    String? content,
    String? authorUsername,
    String? authorAvatar,
    int? likes,
    int? comments,
    String? filter,
    String? mask,
    DateTime? createdAt,
    String? userId,
    List<PostCommentModel>? commentItems,
    List<String>? likedByUserIds,
  }) {
    return PostModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      authorName: authorName ?? this.authorName,
      content: content ?? this.content,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      filter: filter ?? this.filter,
      mask: mask ?? this.mask,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      commentItems: commentItems ?? this.commentItems,
      likedByUserIds: likedByUserIds ?? this.likedByUserIds,
    );
  }

  PostModel toggleLikeLocally(String userId, {required bool like}) {
    final updatedIds = List<String>.from(likedByUserIds);
    if (like) {
      if (!updatedIds.contains(userId)) {
        updatedIds.add(userId);
      }
    } else {
      updatedIds.removeWhere((id) => id == userId);
    }
    final newLikes = like ? likes + 1 : (likes > 0 ? likes - 1 : 0);
    return copyWith(
      likes: newLikes,
      likedByUserIds: List.unmodifiable(updatedIds),
    );
  }

  PostModel withComments(List<PostCommentModel> comments) {
    return copyWith(
      comments: comments.length,
      commentItems: List.unmodifiable(comments),
    );
  }

  static String? _resolveAuthorAvatar(Map<String, dynamic> json) {
    final fromUrl = (json['authorAvatarUrl'] as String?)?.trim();
    if (fromUrl != null && fromUrl.isNotEmpty) return fromUrl;
    final avatar = (json['authorAvatar'] as String?)?.trim();
    if (avatar != null && avatar.isNotEmpty) return avatar;
    return null;
  }

  static int? _extractCount(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toInt();
    if (raw is Iterable) return raw.length;
    if (raw is Map<String, dynamic>) {
      final count = raw['count'];
      if (count is num) return count.toInt();
    }
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static List<String>? _parseStringList(dynamic raw) {
    if (raw is Iterable) {
      final result = raw
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      return result.isEmpty ? null : List.unmodifiable(result);
    }
    return null;
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: false);
    }
    if (raw is String) {
      final parsedInt = int.tryParse(raw);
      if (parsedInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(parsedInt, isUtc: false);
      }
      return DateTime.tryParse(raw);
    }
    return null;
  }

  static List<PostModel> listFrom(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(PostModel.fromJson)
          .toList();
    }
    if (raw is Map<String, dynamic> && raw['data'] is List) {
      return (raw['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(PostModel.fromJson)
          .toList();
    }
    return const [];
  }
}
