import 'package:flutter/material.dart';
import 'package:upsglam_mobile/navigation/app_router.dart';
import 'package:upsglam_mobile/theme/upsglam_theme.dart';
import 'package:upsglam_mobile/views/auth/splash_screen.dart';

void main() {
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
          initialRoute: SplashScreen.routeName,
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}
