import 'dart:async';

import 'package:flutter/material.dart';
import 'package:upsglam_mobile/config/firebase_initializer.dart';
import 'package:upsglam_mobile/models/post.dart';
import 'package:upsglam_mobile/models/post_comment.dart';
import 'package:upsglam_mobile/models/profile.dart';
import 'package:upsglam_mobile/services/auth_service.dart';
import 'package:upsglam_mobile/services/post_service.dart';
import 'package:upsglam_mobile/services/realtime_post_stream_service.dart';
import 'package:upsglam_mobile/services/user_directory_service.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class CommentsView extends StatefulWidget {
  const CommentsView({super.key});

  static const routeName = '/comments';

  @override
  State<CommentsView> createState() => _CommentsViewState();
}

class _OptimisticFingerprint {
  const _OptimisticFingerprint({
    required this.userId,
    required this.normalizedText,
    required this.toleranceMs,
    this.createdAtMs,
  });

  final String userId;
  final String normalizedText;
  final int toleranceMs;
  final int? createdAtMs;

  bool matches(PostCommentModel comment) {
    final candidateUserId = comment.userId.trim();
    if (userId.isNotEmpty && candidateUserId.isNotEmpty && userId != candidateUserId) {
      return false;
    }
    final candidateText = comment.text.trim().toLowerCase();
    if (normalizedText.isNotEmpty && normalizedText != candidateText) {
      return false;
    }
    final candidateCreatedAt = comment.createdAt?.millisecondsSinceEpoch;
    if (createdAtMs == null || candidateCreatedAt == null) {
      return true;
    }
    return (candidateCreatedAt - createdAtMs!).abs() <= toleranceMs;
  }
}

class _CommentsViewState extends State<CommentsView> {
  final PostService _postService = PostService.instance;
  final UserDirectoryService _userDirectoryService = UserDirectoryService.instance;
  final RealtimePostStreamService _realtimeService = RealtimePostStreamService.instance;
  final AuthService _authService = AuthService.instance;
  final TextEditingController _commentController = TextEditingController();
  PostModel? _post;
  bool _sending = false;
  bool _loadingPost = false;
  final Map<String, ProfileModel?> _profileCache = <String, ProfileModel?>{};
  StreamSubscription<PostModel?>? _postSubscription;
  ProfileModel? _currentProfile;
  String? _currentUserId;
  final Set<String> _pendingOptimisticIds = <String>{};
  final Map<String, _OptimisticFingerprint> _optimisticFingerprints =
      <String, _OptimisticFingerprint>{};

  static const int _optimisticMatchToleranceMs = 60000;

  List<PostCommentModel> get _comments => _post?.commentItems ?? const [];

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final initial = ModalRoute.of(context)?.settings.arguments as PostModel?;
    if (_post == null && initial != null) {
      _post = initial;
      _attachRealtime(initial.id);
      _reloadFromBackend(initial.id);
    }
  }

  @override
  void dispose() {
    _postSubscription?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    ProfileModel? profile = await _authService.getStoredProfile();
    final uid = await _authService.getStoredFirebaseUid();
    if ((profile == null || profile.name.trim().isEmpty) && uid != null && uid.isNotEmpty) {
      try {
        profile = await _userDirectoryService.getProfile(uid);
      } on UserDirectoryException catch (error) {
        debugPrint('No se pudo hidratar el perfil local: ${error.message}');
      }
    }
    if (!mounted) return;
    setState(() {
      _currentProfile = profile;
      _currentUserId = uid;
    });
    if (uid != null && uid.isNotEmpty && profile != null) {
      _profileCache[uid] = profile;
    }
  }

  void _popWithResult() {
    Navigator.pop(context, _post);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _reloadFromBackend(String postId) async {
    if (_loadingPost) return;
    setState(() => _loadingPost = true);
    try {
      final fresh = await _postService.fetchPostById(postId);
      final hydrated = await _hydrateComments(fresh);
      if (!mounted) return;
      _applyServerPost(hydrated);
      _applyRealtimeComments(hydrated.commentItems);
    } on PostException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('No se pudieron cargar los comentarios.');
    } finally {
      if (mounted) {
        setState(() => _loadingPost = false);
      }
    }
  }

  void _attachRealtime(String postId) {
    if (postId.isEmpty) return;
    FirebaseInitializer.ensureInitialized().then((_) {
      if (!mounted || !_realtimeService.isAvailable) {
        return;
      }
      _postSubscription?.cancel();
      _postSubscription = _realtimeService.watchPostById(postId).listen(
        (post) {
          if (!mounted || post == null) {
            return;
          }
          _hydrateComments(post).then((hydrated) {
            if (!mounted) return;
            _applyServerPost(hydrated);
            _applyRealtimeComments(hydrated.commentItems);
          });
        },
        onError: (error) => debugPrint('Realtime post stream error: $error'),
      );
    });
  }

  Future<void> _sendComment() async {
    final post = _post;
    if (post == null) {
      _showSnack('No se encontró la publicación.');
      return;
    }
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      _showSnack('Escribe un comentario antes de enviarlo.');
      return;
    }
    final optimisticComment = _buildOptimisticComment(text);
    _registerOptimisticComment(optimisticComment);
    setState(() {
      _sending = true;
      _commentController.clear();
      _post = post.withComments(<PostCommentModel>[...post.commentItems, optimisticComment]);
    });
    try {
      final updated = await _postService.addComment(post.id, text);
      final hydrated = await _hydrateComments(updated);
      if (!mounted) return;
      _applyServerPost(hydrated);
      _applyRealtimeComments(hydrated.commentItems);
    } on PostException catch (error) {
      if (!mounted) return;
      _unregisterOptimisticComment(optimisticComment.id);
      setState(() {
        _post = _removeCommentFromPost(optimisticComment.id);
        _commentController.text = text;
      });
      _showSnack(error.message);
    } catch (_) {
      if (!mounted) return;
      _unregisterOptimisticComment(optimisticComment.id);
      setState(() {
        _post = _removeCommentFromPost(optimisticComment.id);
        _commentController.text = text;
      });
      _showSnack('No se pudo enviar el comentario.');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<PostModel> _hydrateComments(PostModel post) async {
    final needingProfiles = <String>{};
    for (final comment in post.commentItems) {
      if (comment.userId.isEmpty) {
        continue;
      }
      final normalizedAuthor = comment.authorName.trim();
      final needsLookup = comment.needsProfileLookup ||
          normalizedAuthor.isEmpty ||
          normalizedAuthor == PostCommentModel.defaultAuthorName;
      if (needsLookup) {
        needingProfiles.add(comment.userId);
      }
    }
    if (needingProfiles.isEmpty) {
      return post;
    }

    final Map<String, ProfileModel?> resolved = <String, ProfileModel?>{};
    for (final userId in needingProfiles) {
      if (_profileCache.containsKey(userId)) {
        resolved[userId] = _profileCache[userId];
        continue;
      }
      try {
        final profile = await _userDirectoryService.getProfile(userId);
        resolved[userId] = profile;
        _profileCache[userId] = profile;
      } on UserDirectoryException catch (error) {
        debugPrint('User directory error for $userId: ${error.message}');
      }
    }

    final List<PostCommentModel> enriched = post.commentItems.map((comment) {
      final profile = resolved[comment.userId] ?? _profileCache[comment.userId];
      if (profile == null) return comment;
      final normalizedName = profile.name.trim();
      final newName = normalizedName.isNotEmpty ? normalizedName : comment.authorName;
      final newAvatar = profile.avatarUrl?.trim().isNotEmpty == true
          ? profile.avatarUrl
          : comment.authorAvatarUrl;
      if (newName == comment.authorName && newAvatar == comment.authorAvatarUrl) {
        return comment;
      }
      return comment.copyWith(authorName: newName, authorAvatarUrl: newAvatar);
    }).toList(growable: true);

    final uid = _currentUserId;
    ProfileModel? selfProfile = _currentProfile;
    if (selfProfile == null && uid != null && uid.isNotEmpty) {
      selfProfile = _profileCache[uid];
    }
    if (uid != null && uid.isNotEmpty && selfProfile != null) {
      for (var index = 0; index < enriched.length; index++) {
        final comment = enriched[index];
        if (comment.userId != uid) {
          continue;
        }
        final normalizedName = selfProfile.name.trim();
        final resolvedName = normalizedName.isNotEmpty ? normalizedName : comment.authorName;
        final resolvedAvatar = selfProfile.avatarUrl?.trim().isNotEmpty == true
            ? selfProfile.avatarUrl
            : comment.authorAvatarUrl;
        if (resolvedName != comment.authorName || resolvedAvatar != comment.authorAvatarUrl) {
          enriched[index] = comment.copyWith(
            authorName: resolvedName,
            authorAvatarUrl: resolvedAvatar,
          );
        }
      }
    }

    return post.withComments(enriched);
  }

  static const String _optimisticPrefix = 'temp-comment-';

  void _applyServerPost(PostModel serverPost) {
    final current = _post;
    final retainedComments = current?.commentItems ?? const <PostCommentModel>[];
    final hasServerCount = serverPost.commentItems.isNotEmpty || serverPost.comments > 0;
    final nextCount = serverPost.commentItems.isNotEmpty
        ? serverPost.commentItems.length
        : hasServerCount
            ? serverPost.comments
            : retainedComments.length;
    final mergedName = _isPlaceholderName(serverPost.authorName) && current != null
        ? current.authorName
        : serverPost.authorName;
    final mergedAvatar = _preferNonEmpty(serverPost.authorAvatar, current?.authorAvatar);
    final mergedUsername = _preferNonEmpty(serverPost.authorUsername, current?.authorUsername);
    final next = serverPost.copyWith(
      authorName: mergedName,
      authorAvatar: mergedAvatar,
      authorUsername: mergedUsername,
      commentItems: retainedComments,
      comments: nextCount,
    );
    setState(() => _post = next);
  }

  void _applyRealtimeComments(List<PostCommentModel> comments) {
    final post = _post;
    if (post == null) {
      return;
    }
    _expireOptimisticWithSnapshot(comments);
    final filtered = comments
      .where((comment) => !comment.id.startsWith(_optimisticPrefix))
      .toList(growable: false);

    final currentConfirmed = post.commentItems
      .where((comment) => !comment.id.startsWith(_optimisticPrefix))
      .toList(growable: false);
    final optimistic = post.commentItems
      .where(
        (comment) => comment.id.startsWith(_optimisticPrefix) &&
          _pendingOptimisticIds.contains(comment.id),
      )
      .toList(growable: false);

    final shouldReplace = filtered.length >= currentConfirmed.length;
    final mergedConfirmed = _mergeCommentLists(
      currentConfirmed,
      filtered,
      replace: shouldReplace,
    );
    final combined = _sortComments(<PostCommentModel>[...mergedConfirmed, ...optimistic]);
    final updated = post
      .withComments(combined)
      .copyWith(comments: combined.length);
    setState(() => _post = updated);
    _hydrateComments(updated).then((hydrated) {
      if (!mounted) return;
      setState(() => _post = hydrated);
    });
  }

  PostCommentModel _buildOptimisticComment(String text) {
    ProfileModel? profile = _currentProfile;
    final uid = _currentUserId;
    if (profile == null && uid != null && uid.isNotEmpty) {
      profile = _profileCache[uid];
    }
    final rawName = profile?.name ?? '';
    final displayName = rawName.trim().isNotEmpty ? rawName.trim() : PostCommentModel.defaultAuthorName;
    return PostCommentModel(
      id: '$_optimisticPrefix${DateTime.now().microsecondsSinceEpoch}',
      userId: uid ?? '',
      text: text,
      createdAt: DateTime.now(),
      authorName: displayName,
      authorAvatarUrl: profile?.avatarUrl,
    );
  }

  void _registerOptimisticComment(PostCommentModel comment) {
    _pendingOptimisticIds.add(comment.id);
    _optimisticFingerprints[comment.id] = _OptimisticFingerprint(
      userId: comment.userId.trim(),
      normalizedText: comment.text.trim().toLowerCase(),
      createdAtMs: comment.createdAt?.millisecondsSinceEpoch,
      toleranceMs: _optimisticMatchToleranceMs,
    );
  }

  void _unregisterOptimisticComment(String commentId) {
    _pendingOptimisticIds.remove(commentId);
    _optimisticFingerprints.remove(commentId);
  }

  void _expireOptimisticWithSnapshot(List<PostCommentModel> comments) {
    if (_pendingOptimisticIds.isEmpty || comments.isEmpty) {
      return;
    }
    final confirmed = comments
        .where((comment) => !comment.id.startsWith(_optimisticPrefix))
        .toList(growable: false);
    if (confirmed.isEmpty) {
      return;
    }
    final idsToRemove = <String>{};
    for (final optimisticId in _pendingOptimisticIds) {
      final fingerprint = _optimisticFingerprints[optimisticId];
      if (fingerprint == null) {
        idsToRemove.add(optimisticId);
        continue;
      }
      final matched = confirmed.any(fingerprint.matches);
      if (matched) {
        idsToRemove.add(optimisticId);
      }
    }
    if (idsToRemove.isEmpty) {
      return;
    }
    for (final id in idsToRemove) {
      _unregisterOptimisticComment(id);
    }
  }

  List<PostCommentModel> _sortComments(List<PostCommentModel> comments) {
    final sorted = List<PostCommentModel>.from(comments);
    sorted.sort((a, b) {
      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
      if (aTime != bTime) {
        return aTime.compareTo(bTime);
      }
      return a.id.compareTo(b.id);
    });
    return sorted;
  }

  PostModel? _removeCommentFromPost(String commentId) {
    final current = _post;
    if (current == null) {
      return current;
    }
    _unregisterOptimisticComment(commentId);
    final updated = current.commentItems
        .where((comment) => comment.id != commentId)
        .toList(growable: false);
    return current.withComments(updated);
  }

  List<PostCommentModel> _mergeCommentLists(
    List<PostCommentModel> current,
    List<PostCommentModel> incoming, {
    required bool replace,
  }) {
    if (replace) {
      return _sortComments(incoming);
    }
    if (incoming.isEmpty) {
      return _sortComments(current);
    }
    final Map<String, PostCommentModel> byId = {
      for (final item in current) item.id: item,
    };
    for (final comment in incoming) {
      byId[comment.id] = comment;
    }
    return _sortComments(byId.values.toList(growable: false));
  }

  bool _isPlaceholderName(String? name) {
    if (name == null) {
      return true;
    }
    final normalized = name.trim().toLowerCase();
    return normalized.isEmpty || normalized == 'usuario upsglam';
  }

  String? _preferNonEmpty(String? primary, String? fallback) {
    if (primary != null && primary.trim().isNotEmpty) {
      return primary;
    }
    return fallback;
  }

  String _formatTimeAgo(DateTime? date) {
    if (date == null) return 'recién';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'recién';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final post = _post;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _popWithResult();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(post?.authorName ?? 'Comentarios'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _popWithResult,
          ),
        ),
        body: UPSGlamBackground(
          reserveAppBar: true,
          reserveAppBarSpacing: -64,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            child: post == null
              ? const Center(child: Text('No se encontró la publicación.'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassPanel(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comentarios de ${post.authorName}',
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Likes: ${post.likes} · Comentarios: ${post.comments}',
                            style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: GlassPanel(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: _loadingPost
                            ? const Center(child: CircularProgressIndicator())
                            : _comments.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.white38),
                                        const SizedBox(height: 12),
                                        Text('Aún no hay comentarios', style: textTheme.titleMedium),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                itemCount: _comments.length,
                                separatorBuilder: (context, index) => const Divider(),
                                itemBuilder: (context, index) {
                                  final comment = _comments[index];
                                  final avatar = comment.authorAvatarUrl;
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    leading: CircleAvatar(
                                      backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                                      child: avatar == null ? Text(comment.initials) : null,
                                    ),
                                    title: Text(
                                      comment.authorName,
                                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          comment.text,
                                          style: textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatTimeAgo(comment.createdAt),
                                          style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassPanel(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendComment(),
                              decoration: const InputDecoration(
                                hintText: 'Escribe un comentario épico',
                                prefixIcon: Icon(Icons.chat_bubble_outline),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: FilledButton(
                              onPressed: _sending ? null : _sendComment,
                              child: _sending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
