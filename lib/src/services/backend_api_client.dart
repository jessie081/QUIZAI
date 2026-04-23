import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class BackendApiException implements Exception {
  const BackendApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }
    return 'HTTP $statusCode: $message';
  }
}

class BackendApiClient {
  BackendApiClient({
    required this.baseUrl,
    required http.Client httpClient,
    this.timeout = const Duration(seconds: 30),
  }) : _httpClient = httpClient;

  final String baseUrl;
  final http.Client _httpClient;
  final Duration timeout;

  Future<Map<String, dynamic>> getJson(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    http.Response response;

    try {
      response = await _httpClient
          .get(
            uri,
            headers: const <String, String>{
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const BackendApiException(
        'The server took too long to respond.',
      );
    } catch (error) {
      throw const BackendApiException('Could not connect to the backend.');
    }

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    http.Response response;

    try {
      response = await _httpClient
          .post(
            uri,
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const BackendApiException(
        'The server took too long to respond.',
      );
    } catch (error) {
      throw const BackendApiException('Could not connect to the backend.');
    }

    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      throw BackendApiException(
        'The backend returned an empty response.',
        statusCode: response.statusCode,
      );
    }

    late final Map<String, dynamic> decoded;
    try {
      decoded = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );
    } catch (error) {
      throw BackendApiException(
        'The backend returned invalid JSON.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMessage =
          decoded['error'] as String? ??
          decoded['message'] as String? ??
          'Request failed.';
      final details = decoded['details'] as String?;
      throw BackendApiException(
        details != null && details.isNotEmpty
            ? '$errorMessage: $details'
            : errorMessage,
        statusCode: response.statusCode,
      );
    }

    return decoded;
  }
}
