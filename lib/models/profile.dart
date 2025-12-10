class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.name,
    required this.username,
    this.bio,
    this.avatarUrl,
    this.avatarHistory = const <String>[],
    this.createdAt,
  });

  final String id;
  final String name;
  final String username;
  final String? bio;
  final String? avatarUrl;
  final List<String> avatarHistory;
  final DateTime? createdAt;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? json['uid'] as String? ?? '',
      name: (json['name'] as String?)?.trim() ?? 'Sin nombre',
      username: (json['username'] as String?)?.trim() ?? 'sin-username',
      bio: (json['bio'] as String?)?.trim(),
      avatarUrl: (json['avatarUrl'] as String?)?.trim(),
      avatarHistory: _parseHistory(json['avatarHistory']),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (avatarHistory.isNotEmpty) 'avatarHistory': avatarHistory,
        if (createdAt != null) 'createdAt': createdAt!.millisecondsSinceEpoch,
      };

  static List<String> _parseHistory(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<String>()
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
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
    final buffer = StringBuffer();
    final words = name.trim().split(RegExp(r'\s+'));
    for (final word in words.take(2)) {
      if (word.isNotEmpty) buffer.write(word[0].toUpperCase());
    }
    return buffer.isEmpty ? 'UP' : buffer.toString();
  }
}
