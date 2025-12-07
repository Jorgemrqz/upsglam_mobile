import 'package:flutter/material.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class CommentsView extends StatelessWidget {
  const CommentsView({super.key});

  static const routeName = '/comments';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Comentarios en vivo')),
      body: UPSGlamBackground(
        reserveAppBar: true,
        reserveAppBarSpacing: -64,
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassPanel(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Streaming sincronizado',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Los comentarios se procesan a través de WebFlux para baja latencia.',
                    style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: GlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListView.separated(
                  itemBuilder: (context, index) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: CircleAvatar(child: Text('C${index + 1}')),
                    title: Text('Usuario ${index + 1}'),
                    subtitle: const Text('Comentario en tiempo real con latencia < 30ms.'),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite_outline),
                      onPressed: () {},
                    ),
                  ),
                  separatorBuilder: (context, index) => const Divider(),
                  itemCount: 12,
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
                      onPressed: () {},
                      child: const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
