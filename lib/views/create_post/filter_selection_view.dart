import 'package:flutter/material.dart';
import 'package:upsglam_mobile/theme/upsglam_theme.dart';
import 'package:upsglam_mobile/views/create_post/publish_post_view.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class FilterSelectionView extends StatelessWidget {
  const FilterSelectionView({super.key});

  static const routeName = '/filter-selection';
  static const filters = <String>[
    'Sobel',
    'Laplacian',
    'Gaussian',
    'Emboss',
    'UPS Logo',
    'Creativo Libre',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primary = UPSGlamTheme.primary;
    final accent = UPSGlamTheme.accent;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Filtros CUDA')),
      body: UPSGlamBackground(
        reserveAppBar: true,
        reserveAppBarSpacing: -64,
        padding: const EdgeInsets.fromLTRB(18, 28, 18, 16),
        child: Column(
          children: [
            GlassPanel(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_motion_outlined),
                      const SizedBox(width: 8),
                      Text(
                        'Vista previa en GPU',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary.withValues(alpha: 0.7), accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.filter, color: Colors.white54, size: 72),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Selecciona un filtro para procesarlo mediante el microservicio PyCUDA.',
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
                  itemCount: filters.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) => ListTile(
                    leading: CircleAvatar(child: Text(filters[index][0])),
                    title: Text(filters[index]),
                    subtitle: const Text('Renderizado en paralelo · 4 kernels'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {},
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SafeArea(
              top: false,
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, PublishPostView.routeName),
                icon: const Icon(Icons.check_circle),
                label: const Text('Aplicar filtro seleccionado'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
