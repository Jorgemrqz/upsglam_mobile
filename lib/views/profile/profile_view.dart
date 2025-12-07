import 'package:flutter/material.dart';
import 'package:upsglam_mobile/views/auth/login_view.dart';
import 'package:upsglam_mobile/views/profile/edit_profile_view.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  static const routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Perfil del laboratorio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.pushNamed(context, EditProfileView.routeName),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: UPSGlamBackground(
        reserveAppBar: true,
        reserveAppBarSpacing: -64,
        child: Column(
          children: [
            GlassPanel(
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(radius: 40, child: Icon(Icons.person)),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Estudiante UPS',
                                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('Dev paralelo · Quito',
                                style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.auto_awesome, size: 16),
                        label: Text('GPU Tier', style: textTheme.labelMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      _ProfileStat(label: 'Posts', value: '24'),
                      _ProfileStat(label: 'Seguidores', value: '312'),
                      _ProfileStat(label: 'Siguiendo', value: '180'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: GlassPanel(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1B183B), Color(0xFF7B54FF)],
                      ),
                    ),
                    child: Center(
                      child: Text('#${index + 1}', style: textTheme.titleMedium),
                    ),
                  ),
                  itemCount: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                LoginView.routeName,
                (_) => false,
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
      ],
    );
  }
}
