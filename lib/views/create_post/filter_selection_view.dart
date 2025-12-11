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
  static const filters = <String>['Sobel', 'Gaussian', 'Emboss', 'Mean', 'UPS'];
  static const Map<String, List<int>> filterKernelPresets = {
    'Sobel': [3, 9, 15],
    'Gaussian': [31, 71, 141],
    'Emboss': [9, 21, 65],
    'Mean': [3, 5, 7],
    'UPS': [3, 5, 7],
  };

  @override
  State<FilterSelectionView> createState() => _FilterSelectionViewState();
}

class _FilterSelectionViewState extends State<FilterSelectionView> {
  final AuthService _authService = AuthService.instance;
  FilterSelectionArguments? _arguments;
  String _selectedFilter = FilterSelectionView.filters.first;
  int _maskValue = FilterSelectionView.filterKernelPresets[FilterSelectionView.filters.first]!.first;
  bool _processing = false;
  String? _processedUrl;
  String? _originalUrl;
  late final TextEditingController _kernelController;

  @override
  void initState() {
    super.initState();
    final defaultKernel =
        FilterSelectionView.filterKernelPresets[_selectedFilter]?.first ?? 3;
    _kernelController = TextEditingController(text: defaultKernel.toString());
    _maskValue = defaultKernel;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _arguments ??= ModalRoute.of(context)?.settings.arguments as FilterSelectionArguments?;
  }

  @override
  void dispose() {
    _kernelController.dispose();
    super.dispose();
  }

  String get _normalizedFilter => _selectedFilter.toLowerCase();

  List<int> get _currentKernelPresets =>
      FilterSelectionView.filterKernelPresets[_selectedFilter] ?? const [3];

  bool _syncKernelFromInput() {
    final raw = _kernelController.text.trim();
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 3 || parsed.isEven) {
      _showSnack('El kernel debe ser un entero impar mayor o igual a 3.');
      return false;
    }
    _maskValue = parsed;
    return true;
  }

  Future<void> _handleProcess() async {
    final args = _arguments;
    if (args == null) {
      _showSnack('Selecciona una imagen antes de aplicar filtros.');
      return;
    }
    if (!_syncKernelFromInput()) {
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
                                      onSelected: (_) {
                                        if (!selected) {
                                          setState(() {
                                            _selectedFilter = filter;
                                            final defaults =
                                                FilterSelectionView.filterKernelPresets[filter];
                                            final newKernel = (defaults?.first ?? 3).isOdd
                                                ? defaults?.first ?? 3
                                                : 3;
                                            _maskValue = newKernel;
                                            _kernelController.text = newKernel.toString();
                                          });
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 18),
                                Text('Kernel (impar ≥ 3)', style: textTheme.titleMedium),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _kernelController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.memory_outlined),
                                    hintText: 'Ingresa un kernel impar (ej. 31)',
                                    helperText: _selectedFilter == 'UPS'
                                        ? 'UPS valida el kernel pero usa valores fijos.'
                                        : 'Recomendado: ${_currentKernelPresets.join(', ')}',
                                  ),
                                  onSubmitted: (_) => _syncKernelFromInput(),
                                ),
                                const SizedBox(height: 12),
                                if (_currentKernelPresets.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: _currentKernelPresets
                                        .map(
                                          (value) => ActionChip(
                                            label: Text('Kernel $value'),
                                            onPressed: () {
                                              setState(() {
                                                _maskValue = value;
                                                _kernelController.text = value.toString();
                                              });
                                            },
                                          ),
                                        )
                                        .toList(),
                                  ),
                                if (_currentKernelPresets.isNotEmpty) const SizedBox(height: 12),
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
