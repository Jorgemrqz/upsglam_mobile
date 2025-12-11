import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Ensures Firebase is initialized before anything tries to access Firestore.
/// Falls back to the CLI-generated [DefaultFirebaseOptions] when the default
/// initialization fails (for example, on desktop targets).
class FirebaseInitializer {
  FirebaseInitializer._();

  static bool _initialized = false;
  static bool _failed = false;

  static bool get isReady => _initialized;
  static bool get hasError => _failed;

  static Future<void> ensureInitialized() async {
    if (_initialized || _failed) {
      return;
    }

    try {
      if (Firebase.apps.isNotEmpty) {
        _initialized = true;
        return;
      }

      try {
        await Firebase.initializeApp();
        _initialized = true;
        return;
      } catch (_) {
        // Continue with explicit options.
      }

      try {
        final options = DefaultFirebaseOptions.currentPlatform;
        await Firebase.initializeApp(options: options);
        _initialized = true;
      } catch (error, stackTrace) {
        debugPrint('Firebase initialization failed: $error');
        debugPrintStack(label: 'Firebase init stack', stackTrace: stackTrace);
        _failed = true;
      }
    } catch (error, stackTrace) {
      debugPrint('Unexpected Firebase initialization failure: $error');
      debugPrintStack(label: 'Firebase init stack', stackTrace: stackTrace);
      _failed = true;
    }
  }
}
