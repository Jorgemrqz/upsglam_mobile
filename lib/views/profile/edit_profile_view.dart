import 'package:flutter/material.dart';
import 'package:upsglam_mobile/models/profile.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key, this.initialProfile});

  static const routeName = '/edit-profile';

  final ProfileModel? initialProfile;

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  bool _didSave = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile?.name ?? '');
    _bioController = TextEditingController(text: widget.initialProfile?.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final baseProfile = widget.initialProfile;
    if (baseProfile == null) {
      Navigator.pop(context);
      return;
    }
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final trimmedBio = _bioController.text.trim();
    final updated = baseProfile.copyWith(
      name: _nameController.text.trim(),
      bio: trimmedBio.isEmpty ? null : trimmedBio,
    );
    setState(() => _didSave = true);
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final profile = widget.initialProfile;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Editar perfil')),
      body: UPSGlamBackground(
        reserveAppBar: true,
        reserveAppBarSpacing: -64,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassPanel(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundImage:
                          profile?.avatarUrl != null ? NetworkImage(profile!.avatarUrl!) : null,
                      child: profile?.avatarUrl == null
                          ? Text(profile?.initials ?? 'UP', style: textTheme.titleLarge)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text('Actualiza tu identidad visual', style: textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GlassPanel(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre a mostrar',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        helperText: 'Comparte tu rol, enfoque o intereses',
                        prefixIcon: Icon(Icons.edit_note_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _didSave ? null : _handleSave,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
