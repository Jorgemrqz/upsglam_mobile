import 'package:flutter/material.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Ajustes avanzados')),
      body: UPSGlamBackground(
        reserveAppBar: true,
        reserveAppBarSpacing: -64,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Backend WebFlux', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: 'https://backend-webflux.dev/api',
                    decoration: const InputDecoration(
                      labelText: 'URL base',
                      helperText: 'Configura el gateway reactivo para auth/posts',
                      prefixIcon: Icon(Icons.link_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: 'api-key-paralela',
                    decoration: const InputDecoration(
                      labelText: 'API Token opcional',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GlassPanel(
              child: Column(
                children: const [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.info_outline),
                    title: Text('Versión de la app'),
                    subtitle: Text('2.0.0'),
                  ),
                  Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.security_outlined),
                    title: Text('Estado de certificados'),
                    subtitle: Text('Todos los microservicios verificados'),
                  ),
                ],
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar ajustes'),
            ),
          ],
        ),
      ),
    );
  }
}
