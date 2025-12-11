import 'package:flutter/material.dart';
import 'package:upsglam_mobile/models/post.dart';
import 'package:upsglam_mobile/models/post_comment.dart';
import 'package:upsglam_mobile/models/profile.dart';
import 'package:upsglam_mobile/services/post_service.dart';
import 'package:upsglam_mobile/services/user_directory_service.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class CommentsView extends StatefulWidget {
  const CommentsView({super.key});

  static const routeName = '/comments';

  @override
  State<CommentsView> createState() => _CommentsViewState();
}

class _CommentsViewState extends State<CommentsView> {
  final PostService _postService = PostService.instance;
  final UserDirectoryService _userDirectoryService = UserDirectoryService.instance;
  final TextEditingController _commentController = TextEditingController();
  PostModel? _post;
  bool _sending = false;
  bool _loadingPost = false;
  final Map<String, ProfileModel?> _profileCache = <String, ProfileModel?>{};

  List<PostCommentModel> get _comments => _post?.commentItems ?? const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final initial = ModalRoute.of(context)?.settings.arguments as PostModel?;
    if (_post == null && initial != null) {
      _post = initial;
      _reloadFromBackend(initial.id);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<bool> _handleWillPop() async {
    _popWithResult();
    return false;
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
      setState(() => _post = hydrated);
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
    setState(() => _sending = true);
    try {
      final updated = await _postService.addComment(post.id, text);
      final hydrated = await _hydrateComments(updated);
      if (!mounted) return;
      setState(() {
        _post = hydrated;
        _commentController.clear();
      });
    } on PostException catch (error) {
      _showSnack(error.message);
    } catch (_) {
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
      if (comment.needsProfileLookup && comment.userId.isNotEmpty) {
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

    final enriched = post.commentItems.map((comment) {
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
    }).toList();

    return post.withComments(enriched);
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
    return WillPopScope(
      onWillPop: _handleWillPop,
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
