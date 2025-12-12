import 'package:flutter/material.dart';
import 'package:upsglam_mobile/models/profile.dart';
import 'package:upsglam_mobile/services/user_service.dart';
import 'package:upsglam_mobile/views/profile/profile_view.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class UserListView extends StatefulWidget {
  const UserListView({super.key, required this.title, required this.userIds});

  final String title;
  final Set<String> userIds;

  static const routeName = '/user-list';

  @override
  State<UserListView> createState() => _UserListViewState();
}

class _UserListViewState extends State<UserListView> {
  final UserService _userService = UserService.instance;
  List<ProfileModel> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (widget.userIds.isEmpty) {
      setState(() {
        _loading = false;
        _users = [];
      });
      return;
    }

    try {
      // Optimizacion: Si la app escala, esto debe ser un endpoint de batch.
      final allUsers = await _userService.listUsers();
      final filtered = allUsers
          .where((u) => widget.userIds.contains(u.id))
          .toList();

      if (!mounted) return;
      setState(() {
        _users = filtered;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _goToProfile(ProfileModel user) {
    Navigator.pushNamed(context, ProfileView.routeName, arguments: user);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(widget.title), centerTitle: true),
      body: UPSGlamBackground(
        reserveAppBar: true,
        reserveAppBarSpacing: -60,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _users.isEmpty
            ? Center(child: Text('No hay usuarios', style: textTheme.bodyLarge))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return _UserCard(
                    user: user,
                    onTap: () => _goToProfile(user),
                    textTheme: textTheme,
                  );
                },
              ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onTap,
    required this.textTheme,
  });

  final ProfileModel user;
  final VoidCallback onTap;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null ? Text(user.initials) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('@${user.username}', style: textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
