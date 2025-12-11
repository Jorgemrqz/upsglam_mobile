import 'package:flutter/material.dart';
import 'package:upsglam_mobile/models/post.dart';
import 'package:upsglam_mobile/services/post_service.dart';
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
  final List<PostModel> _posts = <PostModel>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
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
                            itemBuilder: (context, index) => _PostCard(post: _posts[index]),
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
  const _PostCard({required this.post});

  final PostModel post;

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
                onPressed: () => Navigator.pushNamed(context, CommentsView.routeName),
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
                icon: const Icon(Icons.favorite_border),
                onPressed: () {},
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
                onPressed: () => Navigator.pushNamed(context, CommentsView.routeName),
                child: Text('Comentarios (${post.comments})'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
