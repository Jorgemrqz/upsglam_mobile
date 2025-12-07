import 'package:flutter/material.dart';
import 'package:upsglam_mobile/views/feed/feed_view.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  static const routeName = '/register';

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, FeedView.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: UPSGlamBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crear cuenta UPSGlam',
                      style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Registro para colaborar en flujos GPU + WebFlux',
                      style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 32),
                    GlassPanel(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nombre completo',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (value) =>
                                  (value == null || value.isEmpty) ? 'Ingresa tu nombre' : null,
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Correo institucional',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Ingresa tu correo';
                                if (!value.contains('@')) return 'Correo inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Ingresa una contraseña';
                                if (value.length < 6) return 'Mínimo 6 caracteres';
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _confirmCtrl,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Confirmar contraseña',
                                prefixIcon: Icon(Icons.lock_person_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Repite la contraseña';
                                }
                                if (value != _passwordCtrl.text) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _isLoading ? null : _createAccount,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.rocket_launch_outlined),
                              label: Text(_isLoading ? 'Sincronizando...' : 'Crear cuenta'),
                            ),
                          ],
                        ),
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
