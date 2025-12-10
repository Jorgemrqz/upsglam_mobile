import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:upsglam_mobile/config/api_config.dart';
import 'package:upsglam_mobile/views/auth/splash_screen.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class GatewaySetupView extends StatefulWidget {
  const GatewaySetupView({super.key});

  static const routeName = '/gateway-setup';

  @override
  State<GatewaySetupView> createState() => _GatewaySetupViewState();
}

class _GatewaySetupViewState extends State<GatewaySetupView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: ApiConfig.currentGatewayBaseUrl ?? '',
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _persistUrl() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await ApiConfig.saveGatewayBaseUrl(_urlController.text);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        SplashScreen.routeName,
        (route) => false,
      );
    } on ArgumentError catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'No se pudo guardar la URL, intenta nuevamente');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _validateUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Ingresa la URL del API Gateway';
    }
    final uri = Uri.tryParse(text);
    if (uri == null || uri.host.isEmpty) {
      return 'URL inválida';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'La URL debe iniciar con http:// o https://';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const navBarColor = Color(0xFF050014);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: navBarColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: UPSGlamBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Configura tu API Gateway',
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Antes de continuar necesitamos saber la URL del backend al que te quieres conectar.',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  GlassPanel(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _urlController,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'URL base',
                              helperText: 'Ejemplo: http://192.168.1.10:8080',
                              prefixIcon: Icon(Icons.link_outlined),
                            ),
                            keyboardType: TextInputType.url,
                            validator: _validateUrl,
                            onFieldSubmitted: (_) => _persistUrl(),
                          ),
                          const SizedBox(height: 16),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _errorMessage!,
                                style: textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                              ),
                            ),
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _persistUrl,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(_isSaving ? 'Guardando...' : 'Guardar y continuar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );

              if (constraints.maxHeight < 620) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: content,
                  ),
                );
              }

              return Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: content,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
