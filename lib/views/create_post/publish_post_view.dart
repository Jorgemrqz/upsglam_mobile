import 'package:flutter/material.dart';
import 'package:upsglam_mobile/models/create_post_arguments.dart';
import 'package:upsglam_mobile/services/post_service.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class PublishPostView extends StatefulWidget {
  const PublishPostView({super.key});

  static const routeName = '/publish-post';

  @override
  State<PublishPostView> createState() => _PublishPostViewState();
}

class _PublishPostViewState extends State<PublishPostView> {
  final TextEditingController _contentController = TextEditingController();
  final PostService _postService = PostService.instance;
  PublishPostArguments? _arguments;
  bool _publishing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _arguments ??=
        ModalRoute.of(context)?.settings.arguments as PublishPostArguments?;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handlePublish() async {
    final args = _arguments;
    if (args == null) {
      _showSnack('Procesa una imagen antes de publicar.');
      return;
    }

    setState(() => _publishing = true);
    try {
      final post = await _postService.createPost(
        imageUrl: args.processedImageUrl,
        content: _contentController.text,
        filter: args.selectedFilter,
        mask: args.maskValue,
      );
      if (!mounted) return;
      Navigator.pop(context, post);
    } on PostException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('No se pudo publicar el post.');
    } finally {
      if (mounted) {
        setState(() => _publishing = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final args = _arguments;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Publicar resultado')),
      body: UPSGlamBackground(
        reserveAppBar: true,
        reserveAppBarSpacing: -64,
        child: args == null
            ? Center(
                child: GlassPanel(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image_outlined, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Aplica un filtro antes de publicar',
                        style: textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GlassPanel(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.network(
                                    args.processedImageUrl,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            height: 300,
                                            width: double.infinity,
                                            color: Colors.black12,
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        },
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              height: 300,
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
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  children: [
                                    if (args.selectedFilter != null)
                                      Chip(label: Text(args.selectedFilter!)),
                                    if (args.maskValue != null)
                                      Chip(
                                        label: Text('Kernel ${args.maskValue}'),
                                      ),
                                    Chip(label: Text(args.fileName)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          GlassPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _contentController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Descripción inspiradora',
                                    hintText:
                                        'Cuenta cómo aceleraste este efecto en CUDA...',
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    const Icon(Icons.cloud_upload_outlined),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Se enviará al microservicio de posts con autenticación JWT.',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          SafeArea(
                            top: false,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FilledButton.icon(
                                onPressed: _publishing ? null : _handlePublish,
                                icon: _publishing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.rocket_launch_outlined),
                                label: Text(
                                  _publishing
                                      ? 'Publicando...'
                                      : 'Publicar en UPSGlam',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
