import 'package:flutter/material.dart';
import 'package:upsglam_mobile/views/auth/register_view.dart';
import 'package:upsglam_mobile/views/feed/feed_view.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  static const routeName = '/login';

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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Bienvenido de vuelta',
                      style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inicia sesión para continuar colaborando en UPSGlam 2.0',
                      style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 32),
                    GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo institucional',
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock_outline),
                              suffixIcon: Icon(Icons.visibility_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text('Olvidé mi contraseña'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              FeedView.routeName,
                            ),
                            child: const Text('Entrar al laboratorio'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    GlassPanel(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Nuevo en UPSGlam?',
                            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              RegisterView.routeName,
                            ),
                            child: const Text('Crear cuenta'),
                          ),
                        ],
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
