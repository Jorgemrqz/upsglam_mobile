import 'package:flutter/material.dart';
import 'package:upsglam_mobile/views/auth/login_view.dart';
import 'package:upsglam_mobile/views/feed/feed_view.dart';
import 'package:upsglam_mobile/widgets/glass_panel.dart';
import 'package:upsglam_mobile/widgets/upsglam_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    final bool isAuthenticated = await _fakeSessionCheck();
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      isAuthenticated ? FeedView.routeName : LoginView.routeName,
    );
  }

  Future<bool> _fakeSessionCheck() async {
    // TODO: reemplazar con consulta real al backend/Firebase
    return false;
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
                        children: const [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Inicializando paralelismo...',
                              overflow: TextOverflow.ellipsis,
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
