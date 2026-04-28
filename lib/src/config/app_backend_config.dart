
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

    // Always use deployed backend (even in debug)
    return const AppBackendConfig(
      baseUrl: 'https://quizai-eight.vercel.app/',
      usesDebugFallback: false,
    );
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
} 