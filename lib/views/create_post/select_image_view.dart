import 'package:flutter/material.dart';
import 'package:upsglam_mobile/theme/upsglam_theme.dart';
import 'package:upsglam_mobile/views/create_post/filter_selection_view.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class SelectImageView extends StatelessWidget {
  const SelectImageView({super.key});

  static const routeName = '/select-image';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primary = UPSGlamTheme.primary;
    final accent = UPSGlamTheme.accent;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Selecciona tu input CUDA')),
      body: UPSGlamBackground(
        reserveAppBar: true,
        reserveAppBarSpacing: -64,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassPanel(
                    padding: EdgeInsets.zero,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: 220,
                        maxHeight: constraints.maxWidth > 480 ? 420 : 320,
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                gradient: LinearGradient(
                                  colors: [primary.withValues(alpha: 0.65), accent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 72,
                                  color: Colors.white38,
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Chip(
                                avatar: const Icon(Icons.speed_outlined, size: 18),
                                label: Text('CUDA Ready', style: textTheme.labelMedium),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassPanel(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(child: Icon(Icons.photo_library_outlined)),
                          title: const Text('Galería paralela'),
                          subtitle: const Text('Importa desde tu carrete para acelerarlo con CUDA.'),
                          trailing: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                            onPressed: () {},
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(child: Icon(Icons.camera_alt_outlined)),
                          title: const Text('Cámara en vivo'),
                          subtitle: const Text('Captura y previsualiza antes de mandar al microservicio.'),
                          trailing: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      FilterSelectionView.routeName,
                    ),
                    icon: const Icon(Icons.tune),
                    label: const Text('Continuar con filtros CUDA'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
