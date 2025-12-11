import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:upsglam_mobile/models/create_post_arguments.dart';
import 'package:upsglam_mobile/models/post.dart';
import 'package:upsglam_mobile/theme/upsglam_theme.dart';
import 'package:upsglam_mobile/views/create_post/filter_selection_view.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class SelectImageView extends StatefulWidget {
  const SelectImageView({super.key});

  static const routeName = '/select-image';

  @override
  State<SelectImageView> createState() => _SelectImageViewState();
}

class _SelectImageViewState extends State<SelectImageView> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _fileName;
  bool _picking = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _picking = true);
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _fileName = picked.name.isNotEmpty ? picked.name : 'post.png';
      });
    } catch (_) {
      _showSnack('No se pudo obtener la imagen, intenta nuevamente.');
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }
    }
  }

  Future<void> _continueToFilters() async {
    if (_imageBytes == null) {
      _showSnack('Selecciona primero una imagen.');
      return;
    }

    final result = await Navigator.pushNamed(
      context,
      FilterSelectionView.routeName,
      arguments: FilterSelectionArguments(
        imageBytes: _imageBytes!,
        fileName: _fileName ?? 'post.png',
      ),
    );

    if (!mounted) return;
    if (result is PostModel) {
      Navigator.pop(context, result);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final primary = UPSGlamTheme.primary;
    final accent = UPSGlamTheme.accent;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Selecciona tu input CUDA')),
      body: UPSGlamBackground(
        reserveAppBar: true,
        reserveAppBarSpacing: -64,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GlassPanel(
                    padding: EdgeInsets.zero,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: 220,
                        maxHeight: constraints.maxWidth > 480 ? 420 : 320,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: _imageBytes == null
                            ? DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primary.withValues(alpha: 0.65), accent],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 72,
                                    color: Colors.white38,
                                  ),
                                ),
                              )
                            : Image.memory(
                                _imageBytes!,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GlassPanel(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(child: Icon(Icons.photo_library_outlined)),
                          title: const Text('Galería paralela'),
                          subtitle: const Text('Importa desde tu carrete para acelerarlo con CUDA.'),
                          trailing: IconButton(
                            icon: _picking
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                            onPressed: _picking ? null : () => _pickImage(ImageSource.gallery),
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(child: Icon(Icons.camera_alt_outlined)),
                          title: const Text('Cámara en vivo'),
                          subtitle:
                              const Text('Captura y previsualiza antes de mandar al microservicio.'),
                          trailing: IconButton(
                            icon: _picking
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                            onPressed: _picking ? null : () => _pickImage(ImageSource.camera),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _picking ? null : _continueToFilters,
                    icon: const Icon(Icons.tune),
                    label: const Text('Continuar con filtros CUDA'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
