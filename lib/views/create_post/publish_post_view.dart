import 'package:flutter/material.dart';
import 'package:upsglam_mobile/views/feed/feed_view.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class PublishPostView extends StatelessWidget {
  const PublishPostView({super.key});

  static const routeName = '/publish-post';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Publicar resultado')),
      body: UPSGlamBackground(
        reserveAppBar: true,
        reserveAppBarSpacing: -64,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                            child: Container(
                              height: 240,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF141434), Color(0xFF7D41FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(Icons.photo, size: 72, color: Colors.white38),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            children: const [
                              Chip(label: Text('Sharpen')),
                              Chip(label: Text('UPS Logo')),
                              Chip(label: Text('PyCUDA')),
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
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Descripción inspiradora',
                              hintText: 'Cuenta cómo aceleraste este efecto...',
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const Icon(Icons.cloud_upload_outlined),
                              const SizedBox(width: 8),
                              Text(
                                'Se publicará en Storage + Firestore',
                                style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
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
                          onPressed: () => Navigator.popUntil(
                            context,
                            ModalRoute.withName(FeedView.routeName),
                          ),
                          icon: const Icon(Icons.rocket_launch_outlined),
                          label: const Text('Publicar en UPSGlam'),
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
