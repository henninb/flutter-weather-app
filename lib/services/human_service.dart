import 'dart:convert';
import 'package:flutter/services.dart';

class HumanService {
  static const _channel = MethodChannel('com.humansecurity/sdk');

  static Future<Map<String, String>> getHeaders() async {
    try {
      final String? headersJson = await _channel
          .invokeMethod<String>('humanGetHeaders')
          .timeout(const Duration(seconds: 5));
      if (headersJson == null || headersJson.isEmpty) return {};
      return Map<String, String>.from(json.decode(headersJson));
    } catch (_) {
      return {};
    }
  }

  /// Returns "solved", "cancelled", or "false" (not a HUMAN block).
  ///
  /// [requestUrl] must be the full URL of the HTTP request that returned this
  /// body (e.g. [Uri.toString] of the GET/POST you made). Required for correct
  /// handling when multiple backends use HUMAN.
  static Future<String> handleResponse({
    required String responseBody,
    required String requestUrl,
  }) async {
    try {
      final out = await _channel.invokeMethod<String>(
        'humanHandleResponse',
        <String, String>{
          'body': responseBody,
          'requestUrl': requestUrl,
        },
      );
      return out ?? 'false';
    } on PlatformException {
      return 'false';
    }
  }
}
