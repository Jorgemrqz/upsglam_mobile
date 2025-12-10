import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  const ApiConfig._();

  static const Duration defaultTimeout = Duration(seconds: 12);
  static const String _gatewayKey = 'upsglam.gatewayBaseUrl';

  static String? _gatewayBaseUrl;
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _gatewayBaseUrl = prefs.getString(_gatewayKey);
    _initialized = true;
  }

  static bool get hasGatewayConfigured =>
      (_gatewayBaseUrl != null && _gatewayBaseUrl!.isNotEmpty);

  static String? get currentGatewayBaseUrl => _gatewayBaseUrl;

  static Future<void> saveGatewayBaseUrl(String rawUrl) async {
    final normalized = _normalizeBaseUrl(rawUrl);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gatewayKey, normalized);
    _gatewayBaseUrl = normalized;
  }

  static Future<void> clearGatewayBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gatewayKey);
    _gatewayBaseUrl = null;
    _initialized = true;
  }

  static Uri uriFor(String endpoint) {
    final base = _gatewayBaseUrl;
    if (base == null || base.isEmpty) {
      throw StateError('La URL del API Gateway no está configurada');
    }

    final sanitizedEndpoint =
        endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$base$sanitizedEndpoint');
  }

  static String _normalizeBaseUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('La URL no puede estar vacía');
    }

    final Uri? parsed = Uri.tryParse(trimmed);
    final hasValidScheme = parsed != null &&
        (parsed.scheme == 'http' || parsed.scheme == 'https');
    if (!hasValidScheme || (parsed.host).isEmpty) {
      throw ArgumentError('Ingresa una URL válida, por ejemplo https://ip:puerto');
    }

    return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  }
}
