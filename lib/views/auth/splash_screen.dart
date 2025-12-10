import 'package:flutter/material.dart';
import 'package:upsglam_mobile/config/api_config.dart';
import 'package:upsglam_mobile/services/auth_service.dart';
import 'package:upsglam_mobile/views/auth/login_view.dart';
import 'package:upsglam_mobile/views/feed/feed_view.dart';
import 'package:upsglam_mobile/views/setup/gateway_setup_view.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService.instance;
  String _statusMessage = 'Inicializando paralelismo...';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    bool isAuthenticated = false;
    if (!mounted) return;
    setState(() {
      _statusMessage = 'Sincronizando con API Gateway...';
    });

    try {
      await ApiConfig.ensureInitialized();
      if (!ApiConfig.hasGatewayConfigured) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, GatewaySetupView.routeName);
        return;
      }
      isAuthenticated = await _authService.hasValidSession();
      if (!mounted) return;
      setState(() {
        _statusMessage = isAuthenticated
            ? 'Sesión verificada, cargando feed'
            : 'Sesión no encontrada, redirigiendo a login';
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _statusMessage = error.message;
      });
    }

    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      isAuthenticated ? FeedView.routeName : LoginView.routeName,
    );
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) => Transform.scale(
                        scale: value,
                        child: child,
                      ),
                      child: const CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white24,
                        child: FlutterLogo(size: 64),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'UPSGlam 2.0',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Creatividad acelerada con GPU + WebFlux',
                      style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    GlassPanel(
                      padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 450),
                              child: Text(
                                _statusMessage,
                                key: ValueKey(_statusMessage),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
