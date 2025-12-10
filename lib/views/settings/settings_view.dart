import 'package:flutter/material.dart';
import 'package:upsglam_mobile/config/api_config.dart';
import 'package:upsglam_mobile/theme/upsglam_theme.dart';
import 'package:upsglam_mobile/views/setup/gateway_setup_view.dart';
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
                      child: FutureBuilder<void>(
                        future: ApiConfig.ensureInitialized(),
                        builder: (context, snapshot) {
                          final String gatewayUrl =
                              ApiConfig.currentGatewayBaseUrl ?? 'No configurado';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Backend WebFlux',
                                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.link_outlined),
                                title: const Text('URL del API Gateway'),
                                subtitle: Text(gatewayUrl),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Toca "Actualizar URL" para cambiar la dirección del backend. Se cerrará la sesión actual.',
                                style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  GatewaySetupView.routeName,
                                ),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Actualizar URL'),
                              ),
                              const SizedBox(height: 24),
                  Text('Paleta visual', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<UPSGlamPalette>(
                    valueListenable: UPSGlamTheme.paletteNotifier,
                    builder: (context, palette, _) {
                      return SegmentedButton<UPSGlamPalette>(
                        segments: [
                          ButtonSegment(
                            value: UPSGlamPalette.glam,
                            label: Text(UPSGlamTheme.paletteLabel(UPSGlamPalette.glam)),
                            icon: const Icon(Icons.bolt),
                          ),
                          ButtonSegment(
                            value: UPSGlamPalette.ups,
                            label: Text(UPSGlamTheme.paletteLabel(UPSGlamPalette.ups)),
                            icon: const Icon(Icons.school),
                          ),
                        ],
                        selected: {palette},
                        onSelectionChanged: (selection) =>
                            UPSGlamTheme.setPalette(selection.first),
                      );
                    },
                  ),
                              const SizedBox(height: 8),
                              Text(
                                'Activa "UPS Institucional" para usar los colores oficiales del logo.',
                                style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                              ),
                            ],
                          );
                        },
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
                    const SizedBox(height: 18),
                    SafeArea(
                      top: false,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Guardar ajustes'),
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
