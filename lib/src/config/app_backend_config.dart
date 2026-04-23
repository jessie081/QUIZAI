import 'package:flutter/foundation.dart';

class AppBackendConfig {
  const AppBackendConfig({
    required this.baseUrl,
    this.usesDebugFallback = false,
  });

  factory AppBackendConfig.fromEnvironment() {
    const configuredBaseUrl = String.fromEnvironment('QUIZPDF_API_BASE_URL');
    if (configuredBaseUrl.trim().isNotEmpty) {
      return const AppBackendConfig(baseUrl: configuredBaseUrl);
    }

    if (kDebugMode) {
      return AppBackendConfig(
        baseUrl: _debugFallbackBaseUrl(),
        usesDebugFallback: true,
      );
    }

    return const AppBackendConfig(baseUrl: '');
  }

  final String baseUrl;
  final bool usesDebugFallback;

  bool get isConfigured => normalizedBaseUrl.isNotEmpty;

  String get normalizedBaseUrl {
    final trimmed = baseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static String _debugFallbackBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://localhost:8080';
    }
  }
}
