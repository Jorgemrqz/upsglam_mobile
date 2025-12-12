import 'dart:async';

import 'package:flutter/material.dart';
import 'package:upsglam_mobile/config/firebase_initializer.dart';
import 'package:upsglam_mobile/models/post.dart';
import 'package:upsglam_mobile/models/profile.dart';
import 'package:upsglam_mobile/services/post_service.dart';
import 'package:upsglam_mobile/services/auth_service.dart';
import 'package:upsglam_mobile/services/realtime_post_stream_service.dart';

import 'package:upsglam_mobile/views/create_post/select_image_view.dart';
import 'package:upsglam_mobile/views/feed/comments_view.dart';
import 'package:upsglam_mobile/views/profile/profile_view.dart';

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
  final RealtimePostStreamService _realtimeService =
      RealtimePostStreamService.instance;
  final List<PostModel> _posts = <PostModel>[];
  final Set<String> _likingPosts = <String>{};
  final Set<String> _managingPosts = <String>{};
  StreamSubscription<List<PostModel>>? _feedSubscription;
  StreamSubscription<ProfileModel>? _profileSubscription;
  String? _currentUserId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _loadFeed();
    _attachRealtimeFeed();
    _profileSubscription = _authService.profileUpdates.listen(
      _onProfileUpdated,
    );
  }

  @override
  @override
  void dispose() {
    _feedSubscription?.cancel();
    _profileSubscription?.cancel();
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
        _sortPosts(_posts);
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
      _feedSubscription = _realtimeService.watchFeed().listen((posts) {
        if (!mounted) return;
        final merged = _mergeRealtimePosts(posts);
        setState(() {
          _posts
            ..clear()
            ..addAll(merged);
          _sortPosts(_posts);
          _loading = false;
        });
      }, onError: (error) => debugPrint('Realtime feed stream error: $error'));
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
        _sortPosts(_posts);
      });
    } on PostException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('No se pudo actualizar el feed.');
    }
  }

  void _onProfileUpdated(ProfileModel profile) {
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < _posts.length; i++) {
        if (_posts[i].userId == profile.id ||
            _posts[i].authorUsername == profile.username) {
          // Actualizamos nombre, avatar y usuario si coincide
          _posts[i] = _posts[i].copyWith(
            authorName: profile.name,
            authorUsername: profile.username,
            authorAvatar: profile.avatarUrl,
          );
        }
      }
    });
  }

  Future<void> _handleCreatePost() async {
    final result = await Navigator.pushNamed(
      context,
      SelectImageView.routeName,
    );
    if (!mounted) return;
    if (result is PostModel) {
      _showSnack('Post publicado ✨');
      _refreshFeed();
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

  bool _isOwner(PostModel post) {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) {
      return false;
    }
    return post.userId == uid;
  }

  Future<String?> _promptEditContent(PostModel post) async {
    final controller = TextEditingController(text: post.content ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar descripción'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Escribe una nueva descripción para tu post',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    if (result == null) {
      return null;
    }
    return result.trim();
  }

  Future<void> _onEditPost(PostModel post) async {
    if (post.id.isEmpty) {
      return;
    }
    final editedContent = await _promptEditContent(post);
    if (editedContent == null) {
      return;
    }
    final currentNormalized = (post.content ?? '').trim();
    if (currentNormalized == editedContent.trim()) {
      _showSnack('No hiciste cambios en la descripción.');
      return;
    }
    setState(() => _managingPosts.add(post.id));
    try {
      final updated = await _postService.updatePostContent(
        post.id,
        editedContent,
      );
      if (!mounted) return;
      setState(() => _replacePost(updated));
      _showSnack('Descripción actualizada ✨');
    } on PostException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('No se pudo editar el post.');
    } finally {
      if (mounted) {
        setState(() => _managingPosts.remove(post.id));
      }
    }
  }

  Future<bool?> _confirmDelete(PostModel post) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar post'),
          content: const Text(
            'Esta acción eliminará el post y todos sus comentarios. ¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onDeletePost(PostModel post) async {
    if (post.id.isEmpty) {
      return;
    }
    final confirmed = await _confirmDelete(post);
    if (confirmed != true) {
      return;
    }
    setState(() => _managingPosts.add(post.id));
    try {
      await _postService.deletePost(post.id);
      if (!mounted) return;
      setState(() {
        _posts.removeWhere((element) => element.id == post.id);
      });
      _showSnack('Post eliminado');
    } on PostException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('No se pudo eliminar el post.');
    } finally {
      if (mounted) {
        setState(() => _managingPosts.remove(post.id));
      }
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

  List<PostModel> _mergeRealtimePosts(List<PostModel> realtimePosts) {
    if (_posts.isEmpty) {
      return List<PostModel>.from(realtimePosts);
    }
    final cachedById = <String, PostModel>{
      for (final post in _posts) post.id: post,
    };
    return realtimePosts
        .map((incoming) {
          final cached = cachedById[incoming.id];
          if (cached == null) {
            return incoming;
          }
          final mergedName = _isPlaceholderName(incoming.authorName)
              ? cached.authorName
              : incoming.authorName;
          final mergedAvatar = _preferNonEmpty(
            incoming.authorAvatar,
            cached.authorAvatar,
          );
          final mergedUsername = _preferNonEmpty(
            incoming.authorUsername,
            cached.authorUsername,
          );
          final mergedFilter = incoming.filter ?? cached.filter;
          final mergedMask = incoming.mask ?? cached.mask;
          return incoming.copyWith(
            authorName: mergedName,
            authorAvatar: mergedAvatar,
            authorUsername: mergedUsername,
            filter: mergedFilter,
            mask: mergedMask,
          );
        })
        .toList(growable: false);
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

  void _sortPosts(List<PostModel> posts) {
    posts.sort(_comparePosts);
  }

  int _comparePosts(PostModel a, PostModel b) {
    final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
    final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
    if (aTime != bTime) {
      return bTime.compareTo(aTime);
    }
    return b.id.compareTo(a.id);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.add_a_photo_outlined),
          tooltip: 'Crear post',
          onPressed: _handleCreatePost,
        ),
        title: Column(
          children: [
            Text(
              'UPSGlam',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontSize: 26, // Aumentado para resaltar más
              ),
            ),
            Text(
              'GPU Filters',
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () =>
                Navigator.pushNamed(context, ProfileView.routeName),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: UPSGlamBackground(
        reserveAppBar: true,
        reserveAppBarSpacing: -64,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          children: [
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
                                const Icon(
                                  Icons.timeline_outlined,
                                  size: 48,
                                  color: Colors.white38,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Aún no hay publicaciones',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sé el primero en subir un filtro desde tu GPU.',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        itemCount: _posts.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          return _PostCard(
                            post: post,
                            liked: post.isLikedBy(_currentUserId),
                            liking: _likingPosts.contains(post.id),
                            onToggleLike: () => _toggleLike(post.id),
                            onOpenComments: () => _openComments(post),
                            canManage: _isOwner(post),
                            managing: _managingPosts.contains(post.id),
                            onEditPost: () => _onEditPost(post),
                            onDeletePost: () => _onDeletePost(post),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
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
    required this.canManage,
    required this.managing,
    this.onEditPost,
    this.onDeletePost,
  });

  final PostModel post;
  final bool liked;
  final VoidCallback onToggleLike;
  final bool liking;
  final VoidCallback onOpenComments;
  final bool canManage;
  final bool managing;
  final VoidCallback? onEditPost;
  final VoidCallback? onDeletePost;

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
                backgroundImage: post.authorAvatar != null
                    ? NetworkImage(post.authorAvatar!)
                    : null,
                child: post.authorAvatar == null ? Text(initials) : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.authorName,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_formatTimeAgo(post.createdAt)} · GPU Filter',
                    style: textTheme.bodySmall?.copyWith(color: Colors.white60),
                  ),
                ],
              ),
              const Spacer(),
              if (canManage && managing)
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: Padding(
                    padding: EdgeInsets.all(6),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (canManage)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEditPost?.call();
                    } else if (value == 'delete') {
                      onDeletePost?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Editar descripción'),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text(
                        'Eliminar post',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: 400,
              width: double.infinity,
              child: Image.network(
                post.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 400,
                    width: double.infinity,
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 400,
                  width: double.infinity,
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: Colors.white38,
                    ),
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
