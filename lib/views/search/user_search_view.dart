import 'package:flutter/material.dart';
import 'package:upsglam_mobile/models/profile.dart';
import 'package:upsglam_mobile/services/user_service.dart';
import 'package:upsglam_mobile/views/profile/profile_view.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class UserSearchView extends StatefulWidget {
  const UserSearchView({super.key});

  static const routeName = '/user-search';

  @override
  State<UserSearchView> createState() => _UserSearchViewState();
}

class _UserSearchViewState extends State<UserSearchView> {
  final UserService _userService = UserService.instance;
  List<ProfileModel> _users = [];
  List<ProfileModel> _filteredUsers = []; // Para búsqueda local si se quiere
  bool _loading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          final name = user.name.toLowerCase();
          final username = user.username.toLowerCase();
          return name.contains(query) || username.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final list = await _userService.listUsers();
      if (!mounted) return;
      setState(() {
        _users = list;
        _filteredUsers = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'No se pudieron cargar los usuarios';
      });
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
      appBar: AppBar(
        title: const Text('Descubrir Personas'),
        centerTitle: true,
      ),
      body: UPSGlamBackground(
        reserveAppBar: true,
        reserveAppBarSpacing: -60,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Buscar usuarios...',
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.white54),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildList(textTheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(TextTheme textTheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.white38),
            const SizedBox(height: 12),
            Text(_errorMessage!, style: textTheme.bodyMedium),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadUsers, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_filteredUsers.isEmpty) {
      return const Center(child: Text('No hay usuarios encontrados'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _UserCard(
          user: user,
          onTap: () => _goToProfile(user),
          textTheme: textTheme,
        );
      },
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
