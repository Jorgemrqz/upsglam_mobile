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

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: (json['id'] as String?) ?? (json['postId'] as String?) ?? '',
      imageUrl: () {
        final rawUrl = (json['imageUrl'] as String?)?.trim();
        if (rawUrl != null && rawUrl.isNotEmpty) {
          return rawUrl;
        }
        return 'https://via.placeholder.com/600x400?text=UPSGlam';
      }(),
      content: (json['content'] as String?)?.trim(),
      authorName: (json['authorName'] as String?)?.trim() ?? 'Usuario UPSGlam',
      authorUsername: (json['authorUsername'] as String?)?.trim(),
      authorAvatar: (json['authorAvatar'] as String?)?.trim(),
      likes: _extractCount(json['likes']) ?? _extractCount(json['likeCount']) ?? 0,
      comments: _extractCount(json['comments']) ?? _extractCount(json['commentCount']) ?? 0,
      filter: (json['filter'] as String?)?.trim(),
      mask: (json['mask'] as String?)?.trim(),
      createdAt: _parseDate(json['createdAt']),
    );
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
      return raw.whereType<Map<String, dynamic>>().map(PostModel.fromJson).toList();
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
