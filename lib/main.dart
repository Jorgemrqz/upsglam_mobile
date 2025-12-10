import 'package:flutter/material.dart';
import 'package:upsglam_mobile/config/api_config.dart';
import 'package:upsglam_mobile/navigation/app_router.dart';
import 'package:upsglam_mobile/theme/upsglam_theme.dart';
import 'package:upsglam_mobile/views/auth/splash_screen.dart';
import 'package:upsglam_mobile/views/setup/gateway_setup_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.ensureInitialized();
  runApp(const UPSGlamApp());
}

class UPSGlamApp extends StatelessWidget {
  const UPSGlamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UPSGlamPalette>(
      valueListenable: UPSGlamTheme.paletteNotifier,
      builder: (context, palette, _) {
        return MaterialApp(
          title: 'UPSGlam 2.0',
          debugShowCheckedModeBanner: false,
          theme: UPSGlamTheme.build(palette: palette),
          initialRoute: ApiConfig.hasGatewayConfigured
              ? SplashScreen.routeName
              : GatewaySetupView.routeName,
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}
