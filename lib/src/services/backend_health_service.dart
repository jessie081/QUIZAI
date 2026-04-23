import '../config/app_backend_config.dart';
import 'backend_api_client.dart';

class BackendHealthStatus {
  const BackendHealthStatus({
    required this.isConfigured,
    required this.isReachable,
    required this.groqConfigured,
    required this.groqWorking,
    required this.modeLabel,
    this.baseUrl,
    this.chatModel,
    this.quizModel,
    this.message,
  });

  final bool isConfigured;
  final bool isReachable;
  final bool groqConfigured;
  final bool groqWorking;
  final String modeLabel;
  final String? baseUrl;
  final String? chatModel;
  final String? quizModel;
  final String? message;
}

class BackendHealthService {
  const BackendHealthService({
    required AppBackendConfig config,
    required BackendApiClient? apiClient,
  })  : _config = config,
        _apiClient = apiClient;

  final AppBackendConfig _config;
  final BackendApiClient? _apiClient;

  Future<BackendHealthStatus> loadStatus() async {
    if (!_config.isConfigured || _apiClient == null) {
      return const BackendHealthStatus(
        isConfigured: false,
        isReachable: false,
        groqConfigured: false,
        groqWorking: false,
        modeLabel: 'Backend not configured',
        message:
            'No backend base URL is configured, so Groq-powered chat and quiz generation are unavailable until the backend is connected.',
      );
    }

    try {
      final json = await _apiClient.getJson('/health');
      final backendReachable = json['backendReachable'] as bool? ?? true;
      final groqConfigured = json['groqConfigured'] as bool? ?? false;
      final groqWorking = json['groqWorking'] as bool? ?? false;
      final details =
          json['details'] as String? ??
          json['message'] as String? ??
          'Backend state could not be determined.';

      final modeLabel = !backendReachable
          ? 'Backend unavailable'
          : !groqConfigured
              ? 'Backend needs Groq key'
              : groqWorking
                  ? 'Live Groq backend'
                  : 'Groq check failed';

      return BackendHealthStatus(
        isConfigured: true,
        isReachable: backendReachable,
        groqConfigured: groqConfigured,
        groqWorking: groqWorking,
        modeLabel: modeLabel,
        baseUrl: _config.normalizedBaseUrl,
        chatModel: json['chat_model'] as String?,
        quizModel: json['quiz_model'] as String?,
        message: _sanitizeStatusMessage(
          isReachable: backendReachable,
          groqConfigured: groqConfigured,
          groqWorking: groqWorking,
          details: details,
        ),
      );
    } on BackendApiException catch (error) {
      return BackendHealthStatus(
        isConfigured: true,
        isReachable: false,
        groqConfigured: false,
        groqWorking: false,
        modeLabel: 'Backend unavailable',
        baseUrl: _config.normalizedBaseUrl,
        message: 'Could not reach the Groq backend right now.',
      );
    } catch (error) {
      return BackendHealthStatus(
        isConfigured: true,
        isReachable: false,
        groqConfigured: false,
        groqWorking: false,
        modeLabel: 'Backend unavailable',
        baseUrl: _config.normalizedBaseUrl,
        message: 'Could not reach the Groq backend right now.',
      );
    }
  }

  String _sanitizeStatusMessage({
    required bool isReachable,
    required bool groqConfigured,
    required bool groqWorking,
    required String details,
  }) {
    final normalized = details.toLowerCase();

    if (!isReachable) {
      return 'Could not reach the Groq backend right now.';
    }

    if (!groqConfigured) {
      return 'Groq is not configured on the server yet.';
    }

    if (groqWorking) {
      return 'Groq is connected and responding normally.';
    }

    if (normalized.contains('401') ||
        normalized.contains('403') ||
        normalized.contains('auth') ||
        normalized.contains('invalid api key') ||
        normalized.contains('api key')) {
      return 'Groq authentication failed. Check the server API key.';
    }

    if (normalized.contains('429') ||
        normalized.contains('rate limit') ||
        normalized.contains('too many requests') ||
        normalized.contains('quota')) {
      return 'Groq is temporarily busy. Please try again in a moment.';
    }

    if (normalized.contains('insufficient balance') ||
        normalized.contains('billing') ||
        normalized.contains('payment')) {
      return 'The Groq backend account needs more balance before AI can respond again.';
    }

    return 'Groq is connected, but the last provider check failed.';
  }
}
