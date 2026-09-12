import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static const String _defaultApiBaseUrl = 'https://187-127-62-64.sslip.io';

  static String get apiBaseUrl {
    String? raw;
    try {
      raw = dotenv.maybeGet('API_URL')?.trim();
    } catch (_) {
      raw = null;
    }
    final value = (raw == null || raw.isEmpty) ? _defaultApiBaseUrl : raw;
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
