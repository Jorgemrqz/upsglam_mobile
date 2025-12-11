class PostCommentModel {
  const PostCommentModel({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.authorName = 'Usuario UPSGlam',
    this.authorAvatarUrl,
  });

  final String id;
  final String userId;
  final String text;
  final DateTime? createdAt;
  final String authorName;
  final String? authorAvatarUrl;

  factory PostCommentModel.fromJson(Map<String, dynamic> json) {
    return PostCommentModel(
      id: (json['id'] as String?)?.trim() ?? '',
      userId: (json['userId'] as String?)?.trim() ?? '',
      text: (json['text'] as String?)?.trim() ?? '',
      authorName: (json['authorName'] as String?)?.trim() ?? 'Usuario UPSGlam',
      authorAvatarUrl: _resolveAvatar(json),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static List<PostCommentModel> listFrom(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(PostCommentModel.fromJson)
          .toList(growable: false);
    }
    return const <PostCommentModel>[];
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

  String get initials {
    final trimmed = authorName.trim();
    if (trimmed.isEmpty) return 'UP';
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'UP';
    final buffer = StringBuffer();
    for (final part in parts.take(2)) {
      buffer.write(part[0].toUpperCase());
    }
    return buffer.toString();
  }

  static String? _resolveAvatar(Map<String, dynamic> json) {
    final fromUrl = (json['authorAvatarUrl'] as String?)?.trim();
    if (fromUrl != null && fromUrl.isNotEmpty) return fromUrl;
    final fallback = (json['authorAvatar'] as String?)?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }
}
