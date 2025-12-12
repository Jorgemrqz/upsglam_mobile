import 'package:flutter/material.dart';
import 'package:upsglam_mobile/models/post.dart';
import 'package:upsglam_mobile/services/auth_service.dart';
import 'package:upsglam_mobile/services/post_service.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class PostDetailView extends StatefulWidget {
  const PostDetailView({super.key});

  static const routeName = '/post-detail';

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  final AuthService _authService = AuthService.instance;
  final PostService _postService = PostService.instance;

  late PostModel _post;
  String? _currentUserId;
  bool _managing = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is PostModel) {
        _post = args;
        _loadSession();
        _initialized = true;
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadSession() async {
    final uid = await _authService.getStoredFirebaseUid();
    if (mounted) {
      setState(() {
        _currentUserId = uid;
      });
    }
  }

  Future<String?> _promptEditContent() async {
    final controller = TextEditingController(text: _post.content ?? '');
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
    if (result == null) return null;
    return result.trim();
  }

  Future<void> _editPost() async {
    final editedContent = await _promptEditContent();
    if (editedContent == null) return;

    final currentNormalized = (_post.content ?? '').trim();
    if (currentNormalized == editedContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hiciste cambios en la descripción.')),
      );
      return;
    }

    setState(() => _managing = true);
    try {
      final updated = await _postService.updatePostContent(
        _post.id,
        editedContent,
      );
      if (mounted) {
        setState(() => _post = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Descripción actualizada ✨')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo editar el post')),
        );
      }
    } finally {
      if (mounted) setState(() => _managing = false);
    }
  }

  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar post'),
        content: const Text('¿Estás seguro de que deseas eliminar este post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _managing = true);
    try {
      await _postService.deletePost(_post.id);
      if (mounted) {
        Navigator.pop(context, true); // Retornar true indicando eliminación
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar el post')),
        );
      }
    } finally {
      if (mounted) setState(() => _managing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isOwner = _currentUserId == _post.userId;

    return UPSGlamBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          title: Transform.translate(
            offset: const Offset(0, -4), // Subimos visualmente el título
            child: const Text('Publicación'),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 40,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (isOwner && _managing)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (isOwner)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    _editPost();
                  } else if (value == 'delete') {
                    _deletePost();
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
        body: SingleChildScrollView(
          // Un pequeño respiro de 10px para que no esté tan pegado
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          child: Column(
            children: [
              GlassPanel(
                borderRadius: 0,
                // Sin padding interno para que la imagen toque bordes si hace falta
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: _post.authorAvatar != null
                                ? NetworkImage(_post.authorAvatar!)
                                : null,
                            child: _post.authorAvatar == null
                                ? Text(
                                    _post.authorName
                                        .substring(0, 1)
                                        .toUpperCase(),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _post.authorName,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'GPU Filter',
                                style: textTheme.bodySmall?.copyWith(
                                  color: Colors.white60,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Image.network(
                      _post.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 300,
                          color: Colors.black12,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
                    if (_post.content != null && _post.content!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _post.content!,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
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
