import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:upsglam_mobile/models/profile.dart';
import 'package:upsglam_mobile/services/auth_service.dart';
import 'package:upsglam_mobile/theme/upsglam_theme.dart';
import 'package:upsglam_mobile/views/auth/login_view.dart';
import 'package:upsglam_mobile/views/profile/edit_profile_view.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  static const routeName = '/profile';

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final AuthService _authService = AuthService.instance;

  ProfileModel? _profile;
  String? _email;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    final profile = await _authService.getStoredProfile();
    final email = await _authService.getStoredEmail();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _email = email;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, LoginView.routeName, (_) => false);
  }

  Future<void> _openEditProfile() async {
    if (_profile == null) return;
    final result = await Navigator.pushNamed(
      context,
      EditProfileView.routeName,
      arguments: _profile,
    );
    if (!mounted) return;
    if (result is ProfileModel) {
      setState(() => _profile = result);
      await _authService.cacheProfile(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final primary = UPSGlamTheme.primary;
    final accent = UPSGlamTheme.accent;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Perfil del laboratorio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loading ? null : _loadProfile,
            tooltip: 'Recargar perfil',
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _profile == null ? null : _openEditProfile,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: UPSGlamBackground(
        reserveAppBar: true,
        reserveAppBarSpacing: -64,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _loading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : _buildBody(textTheme, primary, accent),
        ),
      ),
    );
  }

  Widget _buildBody(TextTheme textTheme, Color primary, Color accent) {
    if (_profile == null) {
      return _buildEmptyState(textTheme);
    }

    final profile = _profile!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(profile, textTheme, primary, accent),
          const SizedBox(height: 18),
          _buildDetails(profile, textTheme),
          const SizedBox(height: 18),
          if (profile.avatarHistory.isNotEmpty)
            _buildAvatarHistory(profile, textTheme)
          else
            _buildBioPanel(profile, textTheme),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ProfileModel profile, TextTheme textTheme, Color primary, Color accent) {
    final avatarImage = _resolveAvatarImage(profile);
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: avatarImage,
                child: avatarImage == null
                    ? Text(profile.initials, style: textTheme.titleLarge)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${profile.username}',
                      style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _email ?? 'Correo no disponible',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: primary.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: accent),
                    const SizedBox(width: 6),
                    Text('GPU Ready', style: textTheme.labelMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.bio?.isNotEmpty == true
                ? profile.bio!
                : 'Comparte tus resultados WebFlux + GPU con la comunidad.',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(ProfileModel profile, TextTheme textTheme) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detalles de la cuenta', style: textTheme.titleMedium),
          const SizedBox(height: 16),
          _ProfileDetailRow(
            icon: Icons.event_available,
            label: 'Creado',
            value: _formatDate(profile.createdAt),
          ),
          const SizedBox(height: 12),
          _ProfileDetailRow(
            icon: Icons.person_outline,
            label: 'Nombre',
            value: profile.name,
          ),
          const SizedBox(height: 12),
          _ProfileDetailRow(
            icon: Icons.alternate_email_outlined,
            label: 'Usuario',
            value: '@${profile.username}',
          ),
        ],
      ),
    );
  }

  ImageProvider<Object>? _resolveAvatarImage(ProfileModel profile) {
    if (profile.avatarData?.isNotEmpty == true) {
      try {
        return MemoryImage(base64Decode(profile.avatarData!));
      } catch (_) {
        // ignore and fallback to URL/initials
      }
    }
    if (profile.avatarUrl?.isNotEmpty == true) {
      return NetworkImage(profile.avatarUrl!);
    }
    return null;
  }

  Widget _buildAvatarHistory(ProfileModel profile, TextTheme textTheme) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historial de avatares', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: profile.avatarHistory
                .map(
                  (url) => CircleAvatar(
                    radius: 26,
                    backgroundImage: NetworkImage(url),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBioPanel(ProfileModel profile, TextTheme textTheme) {
    return GlassPanel(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Biografía', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          Text(
            profile.bio?.isNotEmpty == true
                ? profile.bio!
                : 'Aún no has configurado una bio. Personaliza tu historia desde la web.',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(TextTheme textTheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GlassPanel(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_off_outlined, size: 48),
              const SizedBox(height: 16),
              Text('Aún no hay un perfil vinculado', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Inicia sesión nuevamente para sincronizar tu perfil del backend.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.login_outlined),
                label: const Text('Volver a iniciar sesión'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sin registro';
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
              const SizedBox(height: 2),
              Text(value, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
