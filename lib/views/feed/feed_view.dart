import 'package:flutter/material.dart';
import 'package:upsglam_mobile/views/create_post/select_image_view.dart';
import 'package:upsglam_mobile/views/feed/comments_view.dart';
import 'package:upsglam_mobile/views/profile/profile_view.dart';
import 'package:upsglam_mobile/views/settings/settings_view.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class FeedView extends StatelessWidget {
  const FeedView({super.key});

  static const routeName = '/feed';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                'UPSGlam Feed',
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
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF5FF2C7), Color(0xFF8C6CFF)],
                        ),
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
              child: ListView.separated(
                itemCount: 5,
                separatorBuilder: (context, index) => const SizedBox(height: 20),
                itemBuilder: (context, index) => GlassPanel(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(child: Text('U${index + 2}')),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dev Parallel ${index + 1}',
                                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'hace ${(index + 1) * 3} min · Filtro CUDA',
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
                        child: Container(
                          height: 220,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF211F48), Color(0xFF6F3CFF)],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.image, size: 64, color: Colors.white38),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Snapshot GPU → Gaussian + UPS logo. Sincronizado desde Firestore / WebFlux.',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: const [
                          Chip(label: Text('Gaussian')),
                          Chip(label: Text('UPS Logo')),
                          Chip(label: Text('CUDA')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.favorite_border),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 4),
                          const Text('128'),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.share_outlined),
                            onPressed: () {},
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, CommentsView.routeName),
                            child: const Text('Ver comentarios'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, SelectImageView.routeName),
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Crear post'),
      ),
    );
  }
}
