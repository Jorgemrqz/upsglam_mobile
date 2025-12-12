import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:upsglam_mobile/models/post.dart';
import 'package:upsglam_mobile/models/profile.dart';
import 'package:upsglam_mobile/services/auth_service.dart';
import 'package:upsglam_mobile/services/post_service.dart';
import 'package:upsglam_mobile/services/user_service.dart';
import 'package:upsglam_mobile/theme/upsglam_theme.dart';
import 'package:upsglam_mobile/views/auth/login_view.dart';
import 'package:upsglam_mobile/views/feed/post_detail_view.dart';
import 'package:upsglam_mobile/views/profile/edit_profile_view.dart';
import 'package:upsglam_mobile/views/settings/settings_view.dart';
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
  final PostService _postService = PostService.instance;
  final UserService _userService = UserService.instance;

  ProfileModel? _profile;
  bool _isMe = false;
  bool _isFollowing = false;
  bool _followLoading = false;

  List<PostModel> _userPosts = [];
  bool _postsLoading = false;

  String? _email;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_profile == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is ProfileModel) {
        _initializeWithUser(args);
      } else {
        _loadMyProfile();
      }
    }
  }

  Future<void> _initializeWithUser(ProfileModel user) async {
    setState(() => _loading = true);
    final myProfile = await _authService.getStoredProfile();
    final isMe = myProfile?.id == user.id;

    if (!mounted) return;
    setState(() {
      _profile = user;
      _isMe = isMe;
      _loading = false;
    });

    _loadUserPosts(user.id);
    if (!isMe && myProfile != null) {
      _checkIfFollowing(user.id, myProfile.id);
    }
  }

  Future<void> _loadMyProfile() async {
    setState(() => _loading = true);
    final profile = await _authService.getStoredProfile();
    final email = await _authService.getStoredEmail();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _email = email;
      _isMe = true;
      _loading = false;
    });

    if (profile != null) {
      _loadUserPosts(profile.id);
    }
  }

  Future<void> _checkIfFollowing(String targetId, String myId) async {
    try {
      final following = await _userService.getFollowingIds(myId);
      if (!mounted) return;
      setState(() {
        _isFollowing = following.contains(targetId);
      });
    } catch (_) {
      // Ignorar errores de carga inicial de follow status
    }
  }

  Future<void> _toggleFollow() async {
    if (_profile == null || _followLoading) return;
    setState(() => _followLoading = true);
    try {
      if (_isFollowing) {
        await _userService.unfollowUser(_profile!.id);
      } else {
        await _userService.followUser(_profile!.id);
      }
      if (!mounted) return;
      setState(() {
        _isFollowing = !_isFollowing;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar seguimiento')),
      );
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  Future<void> _loadUserPosts(String userId) async {
    if (!mounted) return;
    setState(() => _postsLoading = true);
    try {
      final posts = await _postService.fetchPostsByUser(userId);
      if (!mounted) return;
      setState(() {
        _userPosts = posts;
      });
    } catch (_) {
      // Manejo silencioso
    } finally {
      if (mounted) {
        setState(() => _postsLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginView.routeName,
      (_) => false,
    );
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
        title: Text(_isMe ? 'Perfil de usuario' : (_profile?.username ?? '')),
        actions: [
          if (_isMe) ...[
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () =>
                  Navigator.pushNamed(context, SettingsView.routeName),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _profile == null ? null : _openEditProfile,
            ),
          ],
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
          if (!_isMe)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton(
                onPressed: _toggleFollow,
                style: FilledButton.styleFrom(
                  backgroundColor: _isFollowing ? Colors.white24 : primary,
                  foregroundColor: Colors.white,
                ),
                child: _followLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isFollowing ? 'Dejar de seguir' : 'Seguir'),
              ),
            ),
          if (!_isMe) const SizedBox(height: 18),
          _buildDetails(profile, textTheme),
          const SizedBox(height: 18),
          if (profile.avatarHistory.isNotEmpty)
            _buildAvatarHistory(profile, textTheme)
          else
            _buildBioPanel(profile, textTheme),
          const SizedBox(height: 24),
          _buildUserPostsGrid(textTheme),
          const SizedBox(height: 24),
          if (_isMe)
            FilledButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ProfileModel profile,
    TextTheme textTheme,
    Color primary,
    Color accent,
  ) {
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
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '@${profile.username}',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    if (_isMe && _email != null) ...[
                      const SizedBox(height: 4),
                      Text(_email!, style: textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.bio?.isNotEmpty == true
                ? profile.bio!
                : (_isMe
                      ? 'Comparte tus resultados WebFlux + GPU con la comunidad.'
                      : 'Sin biografía.'),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _GpuBadge(
              primary: primary,
              accent: accent,
              textTheme: textTheme,
            ),
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
          Text('Detalles', style: textTheme.titleMedium),
          const SizedBox(height: 16),
          _ProfileDetailRow(
            icon: Icons.event_available,
            label: 'Se unió',
            value: _formatDate(profile.createdAt),
          ),
          const SizedBox(height: 12),
          _ProfileDetailRow(
            icon: Icons.person_outline,
            label: 'Nombre completo',
            value: profile.name,
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
        // ignore
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
                : (_isMe
                      ? 'Aún no has configurado una bio.'
                      : 'Sin biografía disponible.'),
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
              Text('Perfil no encontrado', style: textTheme.titleMedium),
              if (_isMe) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _logout,
                  child: const Text('Volver a iniciar sesión'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserPostsGrid(TextTheme textTheme) {
    if (_postsLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (_userPosts.isEmpty) {
      return GlassPanel(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: Colors.white54,
              ),
              const SizedBox(height: 12),
              Text('No hay publicaciones', style: textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: _userPosts.length,
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              PostDetailView.routeName,
              arguments: post,
            ).then((deleted) {
              if (deleted == true && _isMe) {
                if (_profile != null) _loadUserPosts(_profile!.id);
              }
            });
          },
          child: Image.network(
            post.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.black12),
          ),
        );
      },
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
  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

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
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GpuBadge extends StatelessWidget {
  const _GpuBadge({
    required this.primary,
    required this.accent,
    required this.textTheme,
  });

  final Color primary;
  final Color accent;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
