import 'package:flutter/material.dart';
import 'package:upsglam_mobile/models/create_post_arguments.dart';
import 'package:upsglam_mobile/models/post.dart';
import 'package:upsglam_mobile/services/auth_service.dart';
import 'package:upsglam_mobile/theme/upsglam_theme.dart';
import 'package:upsglam_mobile/views/create_post/publish_post_view.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class FilterSelectionView extends StatefulWidget {
  const FilterSelectionView({super.key});

  static const routeName = '/filter-selection';
  static const filters = <String>['Sobel', 'Laplacian', 'Gaussian', 'Emboss', 'UPS Logo'];

  @override
  State<FilterSelectionView> createState() => _FilterSelectionViewState();
}

class _FilterSelectionViewState extends State<FilterSelectionView> {
  final AuthService _authService = AuthService.instance;
  FilterSelectionArguments? _arguments;
  String _selectedFilter = FilterSelectionView.filters.first;
  int _maskValue = 3;
  bool _processing = false;
  String? _processedUrl;
  String? _originalUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _arguments ??= ModalRoute.of(context)?.settings.arguments as FilterSelectionArguments?;
  }

  String get _normalizedFilter => _selectedFilter.toLowerCase().replaceAll(' ', '_');

  Future<void> _handleProcess() async {
    final args = _arguments;
    if (args == null) {
      _showSnack('Selecciona una imagen antes de aplicar filtros.');
      return;
    }
    setState(() => _processing = true);
    try {
      final result = await _authService.processImage(
        bytes: args.imageBytes,
        mask: _maskValue.toString(),
        filter: _normalizedFilter,
        fileName: args.fileName,
      );

      if (result.processedUrl == null || result.processedUrl!.isEmpty) {
        _showSnack('El microservicio no retornó la URL procesada.');
        return;
      }

      setState(() {
        _processedUrl = result.processedUrl;
        _originalUrl = result.originalUrl;
      });
      _showSnack('Filtro aplicado con éxito.');
    } on AuthException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('No se pudo procesar la imagen.');
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _goToPublish() async {
    if (_processedUrl == null) {
      _showSnack('Procesa la imagen antes de continuar.');
      return;
    }

    final result = await Navigator.pushNamed(
      context,
      PublishPostView.routeName,
      arguments: PublishPostArguments(
        processedImageUrl: _processedUrl!,
        fileName: _arguments?.fileName ?? 'post.png',
        originalImageUrl: _originalUrl,
        selectedFilter: _selectedFilter,
        maskValue: _maskValue,
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
    final textTheme = Theme.of(context).textTheme;
    final primary = UPSGlamTheme.primary;
    final accent = UPSGlamTheme.accent;
    final args = _arguments;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Filtros CUDA')),
      body: UPSGlamBackground(
        reserveAppBar: true,
        reserveAppBarSpacing: -64,
        padding: const EdgeInsets.fromLTRB(18, 28, 18, 16),
        child: args == null
            ? Center(
                child: GlassPanel(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image_outlined, size: 48),
                      const SizedBox(height: 12),
                      Text('Selecciona una imagen primero', style: textTheme.titleMedium),
                    ],
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GlassPanel(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.auto_awesome_motion_outlined),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Vista previa en GPU',
                                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: Container(
                                      color: Colors.black,
                                      alignment: Alignment.center,
                                      child: Image.memory(
                                        args.imageBytes,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: _processedUrl == null
                                        ? Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [primary.withValues(alpha: 0.7), accent],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.filter, color: Colors.white54, size: 60),
                                            ),
                                          )
                                        : Container(
                                            color: Colors.black,
                                            alignment: Alignment.center,
                                            child: Image.network(
                                              _processedUrl!,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          GlassPanel(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Selecciona un filtro', style: textTheme.titleMedium),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 8,
                                  children: FilterSelectionView.filters.map((filter) {
                                    final selected = filter == _selectedFilter;
                                    return ChoiceChip(
                                      label: Text(filter),
                                      selected: selected,
                                      onSelected: (_) => setState(() => _selectedFilter = filter),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 18),
                                Text('Tamaño de máscara (odd kernel)', style: textTheme.titleMedium),
                                const SizedBox(height: 8),
                                DropdownButton<int>(
                                  value: _maskValue,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _maskValue = value);
                                    }
                                  },
                                  items: const [3, 5, 7]
                                      .map((value) => DropdownMenuItem(value: value, child: Text('Kernel $value')))
                                      .toList(),
                                ),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: _processing ? null : _handleProcess,
                                  icon: _processing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.auto_fix_high_outlined),
                                  label: Text(_processing ? 'Procesando...' : 'Aplicar filtro en GPU'),
                                ),
                                if (_processedUrl != null) ...[
                                  const SizedBox(height: 12),
                                  SelectableText('Procesada: $_processedUrl', style: textTheme.bodySmall),
                                  if (_originalUrl != null)
                                    SelectableText('Original: $_originalUrl', style: textTheme.bodySmall),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SafeArea(
                            top: false,
                            child: FilledButton.icon(
                              onPressed: _processedUrl == null ? null : _goToPublish,
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Continuar con este filtro'),
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
