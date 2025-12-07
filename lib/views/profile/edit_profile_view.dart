import 'package:flutter/material.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class EditProfileView extends StatelessWidget {
  const EditProfileView({super.key});

  static const routeName = '/edit-profile';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Editar perfil')),
      body: UPSGlamBackground(
        reserveAppBar: true,
        reserveAppBarSpacing: -64,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassPanel(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      const CircleAvatar(radius: 48, child: Icon(Icons.person)),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Actualiza tu identidad visual', style: textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GlassPanel(
              child: Column(
                children: const [
                  TextField(
                    decoration: InputDecoration(labelText: 'Nombre a mostrar'),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(labelText: 'Bio'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}
