import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:upsglam_mobile/models/profile.dart';
import 'package:upsglam_mobile/services/auth_service.dart';
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
  final AuthService _authService = AuthService.instance;
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  bool _saving = false;
  bool _avatarChanged = false;
  Uint8List? _avatarPreview;
  String? _avatarData;
  String? _pendingFileName;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile?.name ?? '');
    _bioController = TextEditingController(text: widget.initialProfile?.bio ?? '');
    _avatarData = widget.initialProfile?.avatarData;
    if (_avatarData?.isNotEmpty == true) {
      try {
        _avatarPreview = base64Decode(_avatarData!);
      } catch (_) {
        _avatarPreview = null;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final baseProfile = widget.initialProfile;
    if (baseProfile == null) {
      Navigator.pop(context);
      return;
    }
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final trimmedBio = _bioController.text.trim();
    await _persistChanges(
      baseProfile,
      _nameController.text.trim(),
      trimmedBio.isEmpty ? '' : trimmedBio,
    );
  }

  Future<void> _persistChanges(ProfileModel baseProfile, String name, String bio) async {
    setState(() => _saving = true);

    try {
      String? updatedAvatarUrl = baseProfile.avatarUrl;
      if (_avatarChanged && _avatarPreview != null) {
        final uploadResult = await _authService.uploadAvatar(
          bytes: _avatarPreview!,
          fileName: _pendingFileName ?? 'avatar.png',
        );
        updatedAvatarUrl = uploadResult.avatarUrl ?? updatedAvatarUrl;
      }

      final updatedProfile = await _authService.updateProfile(
        username: baseProfile.username,
        name: name,
        bio: bio,
        avatarUrl: updatedAvatarUrl,
      );

      final merged = updatedProfile.copyWith(
        avatarData: _avatarData ?? updatedProfile.avatarData,
      );
      await _authService.cacheProfile(merged);

      if (!mounted) return;
      Navigator.pop(context, merged);
    } on AuthException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('No se pudo guardar el perfil. Intenta nuevamente.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _avatarPreview = bytes;
        _avatarData = base64Encode(bytes);
        _pendingFileName = picked.name.isNotEmpty ? picked.name : 'avatar.png';
        _avatarChanged = true;
      });
    } catch (_) {
      _showSnack('No se pudo cargar la imagen seleccionada');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    GlassPanel(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 52,
                            backgroundImage: _avatarPreview != null
                                ? MemoryImage(_avatarPreview!)
                                : profile?.avatarUrl != null
                                    ? NetworkImage(profile!.avatarUrl!)
                                    : null,
                            child: _avatarPreview == null && profile?.avatarUrl == null
                                ? Text(profile?.initials ?? 'UP', style: textTheme.titleLarge)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text('Actualiza tu identidad visual', style: textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _saving ? null : _pickImage,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Seleccionar desde la galería'),
                          ),
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _saving ? null : _handleSave,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
