import 'dart:async';

import 'package:flutter/material.dart';
import 'package:upsglam_mobile/config/firebase_initializer.dart';
import 'package:upsglam_mobile/models/post.dart';
import 'package:upsglam_mobile/services/post_service.dart';
import 'package:upsglam_mobile/services/auth_service.dart';
import 'package:upsglam_mobile/services/realtime_post_stream_service.dart';
import 'package:upsglam_mobile/theme/upsglam_theme.dart';
import 'package:upsglam_mobile/views/create_post/select_image_view.dart';
import 'package:upsglam_mobile/views/feed/comments_view.dart';
import 'package:upsglam_mobile/views/profile/profile_view.dart';
import 'package:upsglam_mobile/views/settings/settings_view.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  static const routeName = '/feed';

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  final PostService _postService = PostService.instance;
  final AuthService _authService = AuthService.instance;
  final RealtimePostStreamService _realtimeService = RealtimePostStreamService.instance;
  final List<PostModel> _posts = <PostModel>[];
  final Set<String> _likingPosts = <String>{};
  StreamSubscription<List<PostModel>>? _feedSubscription;
  String? _currentUserId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _loadFeed();
    _attachRealtimeFeed();
  }

  @override
  void dispose() {
    _feedSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final uid = await _authService.getStoredFirebaseUid();
    if (!mounted) return;
    setState(() => _currentUserId = uid);
  }

  Future<void> _loadFeed() async {
    setState(() => _loading = true);
    try {
      final posts = await _postService.fetchFeed();
      if (!mounted) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(posts);
      });
    } on PostException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('No se pudo cargar el feed.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _attachRealtimeFeed() {
    FirebaseInitializer.ensureInitialized().then((_) {
      if (!mounted || !_realtimeService.isAvailable) {
        return;
      }
      _feedSubscription?.cancel();
      _feedSubscription = _realtimeService.watchFeed().listen(
        (posts) {
          if (!mounted) return;
          setState(() {
            _posts
              ..clear()
              ..addAll(posts);
            _loading = false;
          });
        },
        onError: (error) => debugPrint('Realtime feed stream error: $error'),
      );
    });
  }

  Future<void> _refreshFeed() async {
    try {
      final posts = await _postService.fetchFeed();
      if (!mounted) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(posts);
      });
    } on PostException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('No se pudo actualizar el feed.');
    }
  }

  Future<void> _handleCreatePost() async {
    final result = await Navigator.pushNamed(context, SelectImageView.routeName);
    if (!mounted) return;
    if (result is PostModel) {
      setState(() => _posts.insert(0, result));
      _showSnack('Post publicado ✨');
    }
  }

  Future<void> _openComments(PostModel post) async {
    final result = await Navigator.pushNamed(
      context,
      CommentsView.routeName,
      arguments: post,
    );
    if (!mounted) return;
    if (result is PostModel) {
      setState(() => _replacePost(result));
    }
  }

  Future<void> _toggleLike(String postId) async {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) {
      _showSnack('Debes iniciar sesión para dar like.');
      return;
    }
    if (postId.isEmpty || _likingPosts.contains(postId)) {
      return;
    }

    final index = _posts.indexWhere((element) => element.id == postId);
    if (index == -1) {
      return;
    }
    final current = _posts[index];
    final alreadyLiked = current.isLikedBy(uid);
    final optimistic = current.toggleLikeLocally(uid, like: !alreadyLiked);

    setState(() {
      _likingPosts.add(postId);
      _posts[index] = optimistic;
    });
    try {
      final updated = alreadyLiked
          ? await _postService.unlikePost(postId)
          : await _postService.likePost(postId);
      if (!mounted) return;
      setState(() {
        if (updated.isLikedBy(uid) == alreadyLiked) {
          _replacePost(optimistic);
        } else {
          _replacePost(updated);
        }
      });
    } on PostException catch (error) {
      if (mounted) {
        setState(() => _replacePost(current));
      }
      _showSnack(error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _replacePost(current));
      }
      _showSnack('No se pudo actualizar el like.');
    } finally {
      if (mounted) {
        setState(() => _likingPosts.remove(postId));
      }
    }
  }

  void _replacePost(PostModel updated) {
    final index = _posts.indexWhere((element) => element.id == updated.id);
    if (index != -1) {
      _posts[index] = updated;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primary = UPSGlamTheme.primary;
    final accent = UPSGlamTheme.accent;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UPSGlam',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'GPU Filters · Firestore en vivo',
                style: textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, SettingsView.routeName),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.pushNamed(context, ProfileView.routeName),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: UPSGlamBackground(
        reserveAppBar: true,
        reserveAppBarSpacing: -64,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          children: [
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 10,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) => Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [accent, primary]),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.black,
                        child: Text('U${index + 1}'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Lab ${index + 1}', style: textTheme.labelSmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshFeed,
                child: _loading
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(child: CircularProgressIndicator()),
                        ],
                      )
                    : _posts.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              GlassPanel(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    const Icon(Icons.timeline_outlined, size: 48, color: Colors.white38),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Aún no hay publicaciones',
                                      style:
                                          textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sé el primero en subir un filtro desde tu GPU.',
                                      style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            itemCount: _posts.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              final post = _posts[index];
                              return _PostCard(
                                post: post,
                                liked: post.isLikedBy(_currentUserId),
                                liking: _likingPosts.contains(post.id),
                                onToggleLike: () => _toggleLike(post.id),
                                onOpenComments: () => _openComments(post),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleCreatePost,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Crear post'),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.liked,
    required this.onToggleLike,
    required this.liking,
    required this.onOpenComments,
  });

  final PostModel post;
  final bool liked;
  final VoidCallback onToggleLike;
  final bool liking;
  final VoidCallback onOpenComments;

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
    final chips = <Widget>[];
    if (post.filter != null) {
      chips.add(Chip(label: Text(post.filter!)));
    }
    if (post.mask != null) {
      chips.add(Chip(label: Text('Máscara ${post.mask}')));
    }

    final initials = post.authorName.trim().isNotEmpty
      ? post.authorName.trim().substring(0, 1).toUpperCase()
      : 'UP';

    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage:
                    post.authorAvatar != null ? NetworkImage(post.authorAvatar!) : null,
                child: post.authorAvatar == null
                  ? Text(initials)
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.authorName,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${_formatTimeAgo(post.createdAt)} · GPU Filter',
                    style: textTheme.bodySmall?.copyWith(color: Colors.white60),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: onOpenComments,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.network(
                post.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.white38),
                  ),
                ),
              ),
            ),
          ),
          if (post.content != null && post.content!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(post.content!, style: textTheme.bodyMedium),
          ],
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 12, children: chips),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                icon: liking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        color: liked ? Colors.pinkAccent : null,
                      ),
                onPressed: liking ? null : onToggleLike,
              ),
              const SizedBox(width: 4),
              Text('${post.likes}'),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {},
              ),
              const Spacer(),
              TextButton(
                onPressed: onOpenComments,
                child: Text('Comentarios (${post.comments})'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
